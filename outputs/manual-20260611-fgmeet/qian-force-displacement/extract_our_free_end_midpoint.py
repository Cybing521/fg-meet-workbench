from __future__ import annotations

import csv
import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
WORK_DIR = Path(__file__).resolve().parent
CASE_FILE = ROOT / "cases" / "Thermal_CFFF_U_Vf0.6-30x30-10layer.txt"
MAT_FILE = ROOT / "output" / "static_elastic_U_Vf60_elastic.mat"
MAT_READER = WORK_DIR / "extract_mat_fig_curves.py"
OUT_CSV = WORK_DIR / "our_free_end_midpoint_vs_qian_table23.csv"


def load_mat_reader():
    spec = importlib.util.spec_from_file_location("extract_mat_fig_curves", MAT_READER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load MAT reader from {MAT_READER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_case_nodes(path: Path) -> list[dict[str, object]]:
    text = path.read_text(errors="ignore")
    start = text.index("NODE START") + len("NODE START")
    end = text.index("NODE END", start)
    nodes: list[dict[str, object]] = []
    for raw in text[start:end].splitlines():
        line = raw.strip()
        if not line or line.startswith("-") or line.startswith("*"):
            continue
        parts = line.split()
        if len(parts) < 9:
            continue
        try:
            node_id = int(float(parts[0]))
            coord = (
                round(float(parts[1]), 8),
                round(float(parts[2]), 8),
                round(float(parts[3]), 8),
            )
            flags = tuple(int(round(float(part))) for part in parts[4:9])
        except ValueError:
            continue
        nodes.append({"node_id": node_id, "coord": coord, "flags": flags})
    return nodes


def restore_w_by_node(nodes: list[dict[str, object]], qd: list[float]) -> dict[int, float]:
    q_index = 0
    w_by_node: dict[int, float] = {}
    for node in nodes:
        dofs = []
        for flag in node["flags"]:
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
    return abs(value - reference) / max(abs(reference), 1e-15) * 100.0


def main() -> None:
    mat_reader = load_mat_reader()
    mat = mat_reader.read_mat_file(MAT_FILE)
    qd = mat["Qd"]["data"]
    nodes = parse_case_nodes(CASE_FILE)
    w_by_node = restore_w_by_node(nodes, qd)
    nodes_by_coord = {node["coord"]: node for node in nodes}

    checkpoints = [
        ("fixed_edge_midpoint", (0.0, 0.15, 0.0)),
        ("center", (0.15, 0.15, 0.0)),
        ("x025_y015", (0.25, 0.15, 0.0)),
        ("free_end_midpoint", (0.3, 0.15, 0.0)),
    ]
    extracted = []
    for point, coord in checkpoints:
        node = nodes_by_coord[tuple(round(value, 8) for value in coord)]
        extracted.append(
            {
                "comparison": "our_point_extract",
                "point": point,
                "x_m": coord[0],
                "y_m": coord[1],
                "z_m": coord[2],
                "node_id": node["node_id"],
                "our_matlab_w_mm": 1000.0 * w_by_node[int(node["node_id"])],
                "qian_reference_w_mm": "",
                "rel_err_pct": "",
                "source": "case NODE START + output/static_elastic_U_Vf60_elastic.mat Qd",
                "notes": "direct restored w from case node table",
            }
        )

    free = next(row for row in extracted if row["point"] == "free_end_midpoint")
    free_w_mm = float(free["our_matlab_w_mm"])
    comparisons = [
        {
            "comparison": "our_vs_qian_present",
            "point": "free_end_midpoint",
            "x_m": free["x_m"],
            "y_m": free["y_m"],
            "z_m": free["z_m"],
            "node_id": free["node_id"],
            "our_matlab_w_mm": free_w_mm,
            "qian_reference_w_mm": -5.9976,
            "rel_err_pct": rel_err_pct(-5.9976, free_w_mm),
            "source": "Qian 2026 Table 3",
            "notes": "Both are CFFF square plate 300mm x 300mm x 6mm under 15000 Pa; compare free-end midpoint only",
        },
        {
            "comparison": "our_vs_qian_comsol",
            "point": "free_end_midpoint",
            "x_m": free["x_m"],
            "y_m": free["y_m"],
            "z_m": free["z_m"],
            "node_id": free["node_id"],
            "our_matlab_w_mm": free_w_mm,
            "qian_reference_w_mm": -5.9525,
            "rel_err_pct": rel_err_pct(-5.9525, free_w_mm),
            "source": "Qian 2026 Table 2",
            "notes": "Compare our present-model point with Qian COMSOL convergence value; not a 15-point COMSOL check",
        },
    ]

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8-sig") as handle:
        fieldnames = [
            "comparison",
            "point",
            "x_m",
            "y_m",
            "z_m",
            "node_id",
            "our_matlab_w_mm",
            "qian_reference_w_mm",
            "rel_err_pct",
            "source",
            "notes",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(comparisons)
        writer.writerows(extracted)

    print(f"free_end_midpoint_mm={free_w_mm:.12g}")
    print(f"err_vs_qian_present_pct={comparisons[0]['rel_err_pct']:.6g}")
    print(f"err_vs_qian_comsol_pct={comparisons[1]['rel_err_pct']:.6g}")
    print(f"wrote {OUT_CSV}")


if __name__ == "__main__":
    main()
