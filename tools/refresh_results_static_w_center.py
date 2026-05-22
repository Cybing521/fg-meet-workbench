#!/usr/bin/env python3
"""Refresh w_center_mm in output/results_static.csv from reduced MEET Qd vectors."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
from pathlib import Path
from shutil import copy2
from typing import Any

import scipy.io as sio


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Recompute results_static.csv w_center_mm by restoring reduced Qd "
            "with mechanical DOF constraint flags from each MEET case file."
        )
    )
    parser.add_argument(
        "--input-csv",
        type=Path,
        default=OUTPUT / "results_static.csv",
        help="Existing batch CSV to refresh.",
    )
    parser.add_argument(
        "--output-csv",
        type=Path,
        default=None,
        help="Output CSV. Defaults to in-place overwrite with a timestamped backup.",
    )
    parser.add_argument(
        "--report-csv",
        type=Path,
        default=OUTPUT / "results_static_w_center_refresh_report.csv",
        help="Per-row refresh report.",
    )
    parser.add_argument(
        "--center",
        nargs=3,
        type=float,
        default=(0.15, 0.15, 0.0),
        metavar=("X", "Y", "Z"),
        help="Target center coordinate in meters.",
    )
    return parser.parse_args()


def resolve_path(value: str, base: Path = ROOT) -> Path:
    text = str(value).strip()
    path = Path(text)
    if not path.is_absolute():
        path = base / path
    return path


def read_case_nodes(case_path: Path) -> list[dict[str, Any]]:
    text = case_path.read_text(encoding="utf-8", errors="replace")
    try:
        start = text.index("NODE START") + len("NODE START")
        end = text.index("NODE END", start)
    except ValueError as exc:
        raise ValueError(f"NODE block not found in {case_path}") from exc

    nodes: list[dict[str, Any]] = []
    for raw in text[start:end].splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.endswith(";"):
            line = line[:-1]
        parts = [part for part in line.replace(",", " ").split() if part]
        if len(parts) < 9:
            continue
        nodes.append(
            {
                "node_id": int(round(float(parts[0]))),
                "coord": (float(parts[1]), float(parts[2]), float(parts[3])),
                "flags": tuple(int(round(float(part))) for part in parts[4:9]),
            }
        )
    if not nodes:
        raise ValueError(f"No nodes parsed from {case_path}")
    return nodes


def find_nearest_node_index(nodes: list[dict[str, Any]], target: tuple[float, float, float]) -> int:
    best_index = 0
    best_dist = float("inf")
    for index, node in enumerate(nodes):
        coord = node["coord"]
        dist = sum((coord[i] - target[i]) ** 2 for i in range(3))
        if dist < best_dist:
            best_dist = dist
            best_index = index
    return best_index


def restore_center_w_m(nodes: list[dict[str, Any]], qd, center: tuple[float, float, float]) -> tuple[float, int]:
    center_index = find_nearest_node_index(nodes, center)
    q_index = 0
    center_w = None

    for node_index, node in enumerate(nodes):
        for dof_index, flag in enumerate(node["flags"]):
            value = 0.0
            if flag == 0:
                value = float(qd[q_index])
                q_index += 1
            if node_index == center_index and dof_index == 2:
                center_w = value

    if q_index != len(qd):
        raise ValueError(f"Reduced Qd length mismatch: consumed {q_index}, length {len(qd)}")
    if center_w is None:
        raise ValueError("Center displacement was not restored")
    return center_w, int(nodes[center_index]["node_id"])


def format_float(value: float) -> str:
    return f"{value:.15g}"


def main() -> None:
    args = parse_args()
    input_csv = args.input_csv
    output_csv = args.output_csv or input_csv
    center = tuple(args.center)

    with input_csv.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        if fieldnames is None:
            raise ValueError(f"No header found in {input_csv}")
        rows = list(reader)

    nodes_cache: dict[Path, list[dict[str, Any]]] = {}
    report_rows = []
    changed = 0
    skipped = 0

    for row in rows:
        case_id = row.get("case_id", "")
        status = row.get("status", "")
        if status != "ok":
            skipped += 1
            report_rows.append({"case_id": case_id, "status": "skipped", "message": "status is not ok"})
            continue

        try:
            case_path = resolve_path(row["input_file"])
            mat_path = resolve_path(row["output_mat"])
            if case_path not in nodes_cache:
                nodes_cache[case_path] = read_case_nodes(case_path)
            mat = sio.loadmat(mat_path)
            qd = mat["Qd"].reshape(-1)
            center_w_m, center_node_id = restore_center_w_m(nodes_cache[case_path], qd, center)
            new_w_mm = 1000.0 * center_w_m
            old_w_mm = float(row["w_center_mm"])
            row["w_center_mm"] = format_float(new_w_mm)
            changed += 1
            report_rows.append(
                {
                    "case_id": case_id,
                    "status": "ok",
                    "center_node_id": center_node_id,
                    "old_w_center_mm": format_float(old_w_mm),
                    "new_w_center_mm": format_float(new_w_mm),
                    "diff_w_center_mm": format_float(new_w_mm - old_w_mm),
                    "message": "",
                }
            )
        except Exception as exc:
            skipped += 1
            report_rows.append({"case_id": case_id, "status": "failed", "message": str(exc)})

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    if output_csv == input_csv:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = input_csv.with_name(f"{input_csv.stem}.pre-wcenter-refresh-{stamp}{input_csv.suffix}")
        copy2(input_csv, backup)
        print(f"Backed up {input_csv} -> {backup}")

    with output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    report_fields = [
        "case_id",
        "status",
        "center_node_id",
        "old_w_center_mm",
        "new_w_center_mm",
        "diff_w_center_mm",
        "message",
    ]
    args.report_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.report_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=report_fields)
        writer.writeheader()
        writer.writerows(report_rows)

    failures = [row for row in report_rows if row["status"] == "failed"]
    print(f"Wrote {output_csv}")
    print(f"Wrote {args.report_csv}")
    print(f"Refreshed {changed} rows; skipped {skipped} rows; failures {len(failures)}")
    if failures:
        for row in failures[:10]:
            print(f"FAILED {row['case_id']}: {row['message']}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
