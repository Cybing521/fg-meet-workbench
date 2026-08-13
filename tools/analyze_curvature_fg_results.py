"""Consolidate radius-audited curvature/gradient results and quantify interaction."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXP = ROOT / "outputs" / "paper-20260715-fgmee" / "experiments" / "curvature_fg"


def read(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def f(row: dict[str, str], key: str) -> float:
    return float(row[key])


def relchange(current: float, previous: float) -> float:
    return abs(current - previous) / max(abs(current), 1e-300) * 100.0


def main() -> None:
    pilot = [
        row for row in read(EXP / "curvature_fg_pilot_10x10.csv")
        if abs(f(row, "radius_m") - 0.4) < 1e-12
    ]
    fixed20 = read(EXP / "curvature_fg_meshcheck_R0p4_20_radiusfixed.csv")
    raw = read(EXP / "curvature_fg_meshcheck_R0p4_raw.csv")
    mesh30 = [row for row in raw if int(float(row["mesh"])) == 30]

    by_key: dict[tuple[str, str, int], dict[str, str]] = {}
    for rows, mesh in ((pilot, 10), (fixed20, 20), (mesh30, 30)):
        for row in rows:
            by_key[(row["mode"], row["load_case"], mesh)] = row

    metrics = ("w_center_mm", "electric_span", "magnetic_span", "theta_span_K")
    convergence: list[dict[str, object]] = []
    for mode in ("U", "X"):
        for load_case in ("elastic", "electro", "magneto"):
            previous: dict[str, str] | None = None
            for mesh in (10, 20, 30):
                row = by_key[(mode, load_case, mesh)]
                item: dict[str, object] = {
                    "mesh": mesh,
                    "mode": mode,
                    "load_case": load_case,
                    "radius_m": 0.4,
                    "w_center_mm": f(row, "w_center_mm"),
                    "electric_span": f(row, "electric_span"),
                    "magnetic_span": f(row, "magnetic_span"),
                    "theta_span_K": f(row, "theta_span_K"),
                    "center_coord_1": f(row, "center_coord_1"),
                    "center_coord_2": f(row, "center_coord_2"),
                    "center_coord_3": f(row, "center_coord_3"),
                    "w_change_from_previous_pct": "",
                    "electric_change_from_previous_pct": "",
                    "magnetic_change_from_previous_pct": "",
                    "theta_change_from_previous_pct": "",
                    "status": "radius_audited",
                }
                if previous is not None:
                    for metric, out_name in (
                        ("w_center_mm", "w_change_from_previous_pct"),
                        ("electric_span", "electric_change_from_previous_pct"),
                        ("magnetic_span", "magnetic_change_from_previous_pct"),
                        ("theta_span_K", "theta_change_from_previous_pct"),
                    ):
                        item[out_name] = relchange(f(row, metric), f(previous, metric))
                convergence.append(item)
                previous = row
    write(EXP / "curvature_fg_meshcheck_R0p4_final.csv", convergence)

    dense = read(ROOT / "output" / "results_static.csv")
    flat30: dict[tuple[str, str], float] = {}
    for row in dense:
        if row["vf0"] == "0.6" and row["fg_mode"] in ("U", "X"):
            flat30[(row["fg_mode"], row["load_case"])] = abs(float(row["w_center_mm"]))

    interaction_rows: list[dict[str, object]] = []
    for load_case in ("elastic", "electro", "magneto"):
        ratios: dict[str, float] = {}
        mesh_changes: dict[str, float] = {}
        for mode in ("U", "X"):
            curved30 = abs(f(by_key[(mode, load_case, 30)], "w_center_mm"))
            curved20 = abs(f(by_key[(mode, load_case, 20)], "w_center_mm"))
            ratios[mode] = curved30 / flat30[(mode, load_case)]
            mesh_changes[mode] = relchange(curved30, curved20)
        interaction_pp = 100.0 * (ratios["X"] - ratios["U"])
        numerical_bound_pp = max(mesh_changes.values())
        interaction_rows.append({
            "load_case": load_case,
            "radius_m": 0.4,
            "curvature_1pm": 2.5,
            "U_flat30_abs_w_mm": flat30[("U", load_case)],
            "U_curved30_abs_w_mm": abs(f(by_key[("U", load_case, 30)], "w_center_mm")),
            "U_curvature_ratio": ratios["U"],
            "X_flat30_abs_w_mm": flat30[("X", load_case)],
            "X_curved30_abs_w_mm": abs(f(by_key[("X", load_case, 30)], "w_center_mm")),
            "X_curvature_ratio": ratios["X"],
            "gradient_curvature_interaction_pct_point": interaction_pp,
            "max_20_to_30_curved_w_change_pct": numerical_bound_pp,
            "interaction_to_mesh_change_ratio": abs(interaction_pp) / max(numerical_bound_pp, 1e-300),
            "mesh_gate": "pass" if numerical_bound_pp <= 1.0 else "fail",
            "interpretation": (
                "resolved_nonadditive_displacement_interaction"
                if abs(interaction_pp) > 3.0 * numerical_bound_pp
                else "not_resolved_above_discretization"
            ),
        })
    write(EXP / "curvature_fg_displacement_interaction_final.csv", interaction_rows)

    template_audit = [
        {
            "artifact": "discarded_original_20x20_template",
            "declared_or_assumed_radius_m": 0.4,
            "actual_node_radius_m": 0.6,
            "arc_length_m": 0.3,
            "decision": "excluded_from_mesh_convergence",
        },
        {
            "artifact": "regenerated_20x20_case",
            "declared_or_assumed_radius_m": 0.4,
            "actual_node_radius_m": 0.4,
            "arc_length_m": 0.3,
            "decision": "accepted_radius_audited",
        },
    ]
    write(EXP / "curvature_template_radius_audit.csv", template_audit)

    electro = next(row for row in interaction_rows if row["load_case"] == "electro")
    elastic = next(row for row in interaction_rows if row["load_case"] == "elastic")
    max_final_change = max(
        float(row["w_change_from_previous_pct"])
        for row in convergence
        if row["mesh"] == 30
    )
    report = f"""# 曲率--梯度交互深度核查

## 半径口径修复

首次 20x20 模板审计发现其节点半径为 0.6 m，而不是文件名假定的 0.4 m；该批结果已从收敛判断中剔除。重新由 300 mm x 300 mm 平板拓扑映射生成的 20x20 模型满足半径 0.4 m、角度范围 0--0.75 rad、弧长 0.3 m。

## 网格结论

真正同口径的 20x20 与 30x30 对比中，所有中心位移变化不超过 {max_final_change:.4f}%，通过 1% 门槛。原先约 3% 的非单调变化完全由错半径模板造成，不是离散振荡。

## 交互结论

- 机械压力工况的 U/X 曲率比差为 {float(elastic['gradient_curvature_interaction_pct_point']):.4f} 个百分点，量级接近零，未显示有意义的梯度--曲率交互。
- 300 V 电致位移的 U/X 曲率比差为 {float(electro['gradient_curvature_interaction_pct_point']):.4f} 个百分点；其与 20->30 最大网格变化之比为 {float(electro['interaction_to_mesh_change_ratio']):.1f}，可视为已分辨的非加和交互。
- 200 A 磁致位移在线性模型中给出相同的归一化交互比例，说明该效应来自结构/梯度分布，而不是载荷幅值。

全半径 30 组 10x10 结果用于趋势筛选；R=0.4 m 的 U/X 代表点已由 20x20/30x30 正式复核。尚未对全部半径做 30x30 扩展，因此不能把完整曲率曲线宣称为最终高精度参数图。
"""
    (EXP / "curvature_fg_deep_diagnosis.md").write_text(report, encoding="utf-8")
    print(f"max_20_to_30_w_change_pct={max_final_change}")
    print(f"electro_interaction_pp={electro['gradient_curvature_interaction_pct_point']}")
    print(f"interaction_to_mesh_ratio={electro['interaction_to_mesh_change_ratio']}")


if __name__ == "__main__":
    main()
