#!/usr/bin/env python3
"""Compare parameterized COMSOL validation points with MATLAB MEET results."""

from __future__ import annotations

import argparse
import csv
from datetime import date
from pathlib import Path

import scipy.io as sio


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output"
COMSOL_RESULTS = ROOT / "comsol" / "results"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--comsol-csv", type=Path, required=True)
    parser.add_argument("--meet-mat", type=Path, required=True)
    parser.add_argument("--case-file", type=Path, required=True)
    parser.add_argument("--point-out", type=Path, required=True)
    parser.add_argument("--log-out", type=Path, default=COMSOL_RESULTS / "validation_log_generated.csv")
    parser.add_argument("--summary-out", type=Path, default=None)
    parser.add_argument("--run-tag", required=True)
    parser.add_argument("--case-id", required=True)
    parser.add_argument("--fg-mode", required=True)
    parser.add_argument("--vf0", required=True)
    parser.add_argument("--bc", required=True)
    parser.add_argument("--comsol-mesh", default="3D solid 10-domain CSV materials, swept quad/hex mesh")
    parser.add_argument("--notes-extra", default="")
    parser.add_argument("--date", default=date.today().isoformat())
    return parser.parse_args()


def parse_case_nodes(path: Path) -> list[dict[str, object]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    start = text.index("NODE START") + len("NODE START")
    end = text.index("NODE END", start)
    nodes = []
    for raw in text[start:end].splitlines():
        line = raw.strip().rstrip(";")
        if not line or not line[0].isdigit():
            continue
        parts = line.split()
        if len(parts) < 9:
            continue
        node_id = int(float(parts[0]))
        coord = (round(float(parts[1]), 8), round(float(parts[2]), 8), round(float(parts[3]), 8))
        flags = tuple(int(round(float(part))) for part in parts[4:9])
        nodes.append({"node_id": node_id, "coord": coord, "flags": flags})
    return nodes


def restore_full_tqd(nodes: list[dict[str, object]], qd) -> list[float]:
    q_index = 0
    full = []
    for node in nodes:
        for flag in node["flags"]:
            if flag == 0:
                full.append(float(qd[q_index]))
                q_index += 1
            else:
                full.append(0.0)
    if q_index != len(qd):
        raise ValueError(f"Reduced Qd length mismatch: consumed {q_index}, length {len(qd)}")
    return full


def load_w_by_coord(case_file: Path, meet_mat: Path) -> dict[tuple[float, float, float], float]:
    nodes = parse_case_nodes(case_file)
    mat = sio.loadmat(meet_mat, squeeze_me=True, struct_as_record=False)
    if "TQd" in mat:
        tqd = [float(x) for x in mat["TQd"].reshape(-1)]
    else:
        tqd = restore_full_tqd(nodes, mat["Qd"].reshape(-1))
    if len(tqd) != len(nodes) * 5:
        raise ValueError(f"Full TQd length mismatch: {len(tqd)} vs {len(nodes) * 5}")
    return {node["coord"]: tqd[i * 5 + 2] for i, node in enumerate(nodes)}


def rel_err_pct(reference: float, value: float) -> float:
    return abs(value - reference) / max(abs(reference), 1e-15) * 100.0


def main() -> None:
    args = parse_args()
    for path in [args.comsol_csv, args.meet_mat, args.case_file]:
        if not path.is_file():
            raise FileNotFoundError(path)
    args.point_out.parent.mkdir(parents=True, exist_ok=True)
    args.log_out.parent.mkdir(parents=True, exist_ok=True)
    if args.summary_out is not None:
        args.summary_out.parent.mkdir(parents=True, exist_ok=True)

    matlab_w_by_coord = load_w_by_coord(args.case_file, args.meet_mat)
    rows = []
    with args.comsol_csv.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            coord = (
                round(float(row["x_m"]), 8),
                round(float(row["y_m"]), 8),
                round(float(row["z_m"]), 8),
            )
            matlab_w_m = matlab_w_by_coord[coord]
            comsol_w_m = float(row["comsol_w_m"])
            matlab_w_mm = 1000.0 * matlab_w_m
            comsol_w_mm = 1000.0 * comsol_w_m
            diff_mm = comsol_w_mm - matlab_w_mm
            rows.append(
                {
                    **row,
                    "matlab_w_m": matlab_w_m,
                    "matlab_w_mm": matlab_w_mm,
                    "diff_w_mm": diff_mm,
                    "rel_err_w_pct": rel_err_pct(matlab_w_mm, comsol_w_mm),
                }
            )

    with args.point_out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    center = next(row for row in rows if row["point_id"] == "p8")
    max_abs_diff = max(abs(float(row["diff_w_mm"])) for row in rows)
    max_rel_err = max(float(row["rel_err_w_pct"]) for row in rows)
    mean_rel_err = sum(float(row["rel_err_w_pct"]) for row in rows) / len(rows)
    notes = (
        f"15-point comparison; max_abs_diff_mm={max_abs_diff:.6g}; "
        f"max_rel_err_pct={max_rel_err:.6g}; mean_rel_err_pct={mean_rel_err:.6g}"
    )
    if args.notes_extra:
        notes = f"{notes}; {args.notes_extra}"

    log_exists = args.log_out.exists()
    with args.log_out.open("a", newline="", encoding="utf-8") as f:
        fieldnames = [
            "case_id",
            "fg_mode",
            "vf0",
            "load_case",
            "bc",
            "matlab_w_mm",
            "comsol_w_mm",
            "rel_err_w_pct",
            "matlab_theta_K",
            "comsol_theta_K",
            "rel_err_theta_pct",
            "matlab_mesh",
            "comsol_mesh",
            "notes",
            "date",
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not log_exists:
            writer.writeheader()
        writer.writerow(
            {
                "case_id": args.case_id,
                "fg_mode": args.fg_mode,
                "vf0": args.vf0,
                "load_case": "elastic",
                "bc": args.bc,
                "matlab_w_mm": center["matlab_w_mm"],
                "comsol_w_mm": center["comsol_w_mm"],
                "rel_err_w_pct": center["rel_err_w_pct"],
                "matlab_theta_K": "",
                "comsol_theta_K": "",
                "rel_err_theta_pct": "",
                "matlab_mesh": "30x30 MEET",
                "comsol_mesh": args.comsol_mesh,
                "notes": notes,
                "date": args.date,
            }
        )

    if args.summary_out is not None:
        summary_exists = args.summary_out.exists()
        with args.summary_out.open("a", newline="", encoding="utf-8") as f:
            fieldnames = [
                "run_tag",
                "case_id",
                "comsol_csv",
                "matlab_w_p8_mm",
                "comsol_w_p8_mm",
                "center_rel_err_pct",
                "max_abs_diff_mm",
                "max_rel_err_pct",
                "mean_rel_err_pct",
                "comsol_mesh",
                "notes",
                "date",
            ]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            if not summary_exists:
                writer.writeheader()
            writer.writerow(
                {
                    "run_tag": args.run_tag,
                    "case_id": args.case_id,
                    "comsol_csv": str(args.comsol_csv),
                    "matlab_w_p8_mm": center["matlab_w_mm"],
                    "comsol_w_p8_mm": center["comsol_w_mm"],
                    "center_rel_err_pct": center["rel_err_w_pct"],
                    "max_abs_diff_mm": max_abs_diff,
                    "max_rel_err_pct": max_rel_err,
                    "mean_rel_err_pct": mean_rel_err,
                    "comsol_mesh": args.comsol_mesh,
                    "notes": args.notes_extra,
                    "date": args.date,
                }
            )

    print(f"Wrote {args.point_out}")
    print(f"Updated {args.log_out}")
    if args.summary_out is not None:
        print(f"Updated {args.summary_out}")
    print(
        "center p8: MATLAB={:.6g} mm, COMSOL={:.6g} mm, rel_err={:.3f}%".format(
            float(center["matlab_w_mm"]),
            float(center["comsol_w_mm"]),
            float(center["rel_err_w_pct"]),
        )
    )
    print(
        "15-point max_abs_diff={:.6g} mm, max_rel_err={:.3f}%, mean_rel_err={:.3f}%".format(
            max_abs_diff, max_rel_err, mean_rel_err
        )
    )


if __name__ == "__main__":
    main()
