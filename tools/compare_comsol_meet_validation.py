#!/usr/bin/env python3
"""Compare COMSOL validation points with MEET MATLAB results."""

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
    parser = argparse.ArgumentParser(
        description="Compare COMSOL U/Vf0.6/CFFF elastic validation points with MATLAB MEET results."
    )
    parser.add_argument(
        "--comsol-csv",
        type=Path,
        default=OUTPUT / "comsol_elastic_cfff_U_Vf06_points.csv",
        help="COMSOL point CSV to compare.",
    )
    parser.add_argument(
        "--meet-mat",
        type=Path,
        default=OUTPUT / "static_elastic_U_Vf60_elastic.mat",
        help="MATLAB .mat file containing Qd.",
    )
    parser.add_argument(
        "--meet-nodes-txt",
        type=Path,
        default=OUTPUT / "LINEAR_DataUsed_runtime.txt",
        help="MATLAB runtime text containing the Node table.",
    )
    parser.add_argument(
        "--point-out",
        type=Path,
        default=COMSOL_RESULTS / "validation_points_U_Vf06_elastic.csv",
        help="Per-point comparison CSV to write.",
    )
    parser.add_argument(
        "--log-out",
        type=Path,
        default=COMSOL_RESULTS / "validation_log.csv",
        help="One-row validation log CSV to write.",
    )
    parser.add_argument(
        "--summary-out",
        type=Path,
        default=None,
        help="Optional experiment summary CSV to append.",
    )
    parser.add_argument(
        "--run-tag",
        default="default",
        help="Short experiment tag used in the optional summary file.",
    )
    parser.add_argument(
        "--comsol-mesh",
        default="3D solid auto mesh size 5, equivalent homogeneous U layer",
        help="Human-readable COMSOL mesh/model description for the log.",
    )
    parser.add_argument(
        "--notes-extra",
        default="",
        help="Extra note text appended to the validation log notes.",
    )
    parser.add_argument(
        "--date",
        default=date.today().isoformat(),
        help="Validation date written to logs.",
    )
    return parser.parse_args()


def parse_meet_nodes(path: Path) -> list[dict[str, object]]:
    text = path.read_text(errors="ignore")
    start = text.index("Node =") + len("Node =")
    nodes: list[dict[str, object]] = []
    started = False
    for raw in text[start:].splitlines():
        line = raw.strip()
        if not line:
            if started:
                break
            continue
        if line.startswith("*"):
            break
        started = True
        if line.endswith(";"):
            line = line[:-1]
        parts = [part for part in line.split(",") if part]
        if len(parts) < 9:
            continue
        node_id = int(parts[0])
        coord = (round(float(parts[1]), 8), round(float(parts[2]), 8), round(float(parts[3]), 8))
        flags = tuple(int(round(float(part))) for part in parts[4:9])
        nodes.append({"node_id": node_id, "coord": coord, "flags": flags})
    return nodes


def restore_meet_w_by_node(nodes: list[dict[str, object]], qd) -> dict[int, float]:
    """Restore reduced MEET mechanical DOFs to full nodal w displacement."""
    q_index = 0
    w_by_node: dict[int, float] = {}
    for node in nodes:
        dofs = []
        flags = node["flags"]
        for flag in flags:
            if flag == 0:
                dofs.append(float(qd[q_index]))
                q_index += 1
            else:
                dofs.append(0.0)
        w_by_node[int(node["node_id"])] = dofs[2]
    if q_index != len(qd):
        raise ValueError(f"Reduced Qd length mismatch: consumed {q_index}, length {len(qd)}")
    return w_by_node


def rel_err_pct(reference: float, value: float) -> float:
    denom = max(abs(reference), 1e-15)
    return abs(value - reference) / denom * 100.0


def main() -> None:
    args = parse_args()
    comsol_csv = args.comsol_csv
    meet_mat = args.meet_mat
    meet_nodes_txt = args.meet_nodes_txt
    point_out = args.point_out
    log_out = args.log_out

    point_out.parent.mkdir(parents=True, exist_ok=True)
    log_out.parent.mkdir(parents=True, exist_ok=True)
    if args.summary_out is not None:
        args.summary_out.parent.mkdir(parents=True, exist_ok=True)

    nodes = parse_meet_nodes(meet_nodes_txt)
    nodes_by_coord = {node["coord"]: int(node["node_id"]) for node in nodes}
    mat = sio.loadmat(meet_mat)
    qd = mat["Qd"].reshape(-1)
    w_by_node = restore_meet_w_by_node(nodes, qd)

    rows = []
    with comsol_csv.open(newline="") as f:
        for row in csv.DictReader(f):
            key = (
                round(float(row["x_m"]), 8),
                round(float(row["y_m"]), 8),
                round(float(row["z_m"]), 8),
            )
            if key not in nodes_by_coord:
                raise KeyError(f"MEET node not found for validation point {key}")
            node_id = nodes_by_coord[key]
            matlab_w_m = float(w_by_node[node_id])
            comsol_w_m = float(row["comsol_w_m"])
            matlab_w_mm = 1000.0 * matlab_w_m
            comsol_w_mm = float(row["comsol_w_mm"])
            diff_mm = comsol_w_mm - matlab_w_mm
            rows.append(
                {
                    **row,
                    "meet_node_id": node_id,
                    "matlab_w_m": matlab_w_m,
                    "matlab_w_mm": matlab_w_mm,
                    "diff_w_mm": diff_mm,
                    "rel_err_w_pct": rel_err_pct(matlab_w_mm, comsol_w_mm),
                }
            )

    fieldnames = list(rows[0].keys())
    with point_out.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
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
        notes = notes + "; " + args.notes_extra

    with log_out.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
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
            ],
        )
        writer.writeheader()
        writer.writerow(
            {
                "case_id": "U_Vf06_elastic",
                "fg_mode": "U",
                "vf0": "0.6",
                "load_case": "elastic",
                "bc": "CFFF",
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
        with args.summary_out.open("a", newline="") as f:
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
                    "case_id": "U_Vf06_elastic",
                    "comsol_csv": str(comsol_csv),
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

    print(f"Wrote {point_out}")
    print(f"Wrote {log_out}")
    if args.summary_out is not None:
        print(f"Appended {args.summary_out}")
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
