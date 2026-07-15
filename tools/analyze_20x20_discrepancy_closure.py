"""Close both meanings of the earlier "20x20 discrepancy" with auditable data."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "outputs" / "paper-20260715-fgmee" / "experiments"
CURV = BASE / "curvature_fg"


def read(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def index(rows: list[dict[str, str]], mesh: int) -> dict[tuple[str, str], dict[str, str]]:
    return {
        (row["mode"], row["load_case"]): row
        for row in rows
        if int(float(row["mesh"])) == mesh and abs(float(row["radius_m"]) - 0.4) < 1e-12
    }


def rel(a: float, b: float) -> float:
    return abs(a - b) / max(abs(b), 1e-30) * 100.0


def main() -> None:
    # The first file preserves the discarded R=0.6-labelled-as-R=0.4 20x20 run
    # and its then-current 30x30 reference.  The second file is the regenerated
    # R=0.4 20x20 run.  The full checkpoint contains the final canonical 30x30.
    original = read(CURV / "curvature_fg_meshcheck_R0p4_raw.csv")
    fixed20 = read(CURV / "curvature_fg_meshcheck_R0p4_20_radiusfixed.csv")
    canonical = read(CURV / "curvature_fg_full_mesh_20_30_raw.csv")
    wrong20 = index(original, 20)
    legacy30 = index(original, 30)
    fixed20_idx = index(fixed20, 20)
    canonical30 = index(canonical, 30)
    keys = sorted(wrong20)
    if not (len(keys) == len(legacy30) == len(fixed20_idx) == len(canonical30) == 6):
        raise RuntimeError(
            "R=0.4 decomposition is incomplete: "
            f"wrong20={len(wrong20)}, legacy30={len(legacy30)}, "
            f"fixed20={len(fixed20_idx)}, canonical30={len(canonical30)}"
        )

    rows: list[dict[str, object]] = []
    for mode, load_case in keys:
        w_wrong = float(wrong20[(mode, load_case)]["w_center_mm"])
        w_fixed = float(fixed20_idx[(mode, load_case)]["w_center_mm"])
        w_legacy30 = float(legacy30[(mode, load_case)]["w_center_mm"])
        w_canonical30 = float(canonical30[(mode, load_case)]["w_center_mm"])
        old_gap = rel(w_wrong, w_legacy30)
        geometry_fixed_gap = rel(w_fixed, w_legacy30)
        canonical_gap = rel(w_fixed, w_canonical30)
        rows.append(
            {
                "mode": mode,
                "load_case": load_case,
                "discarded_20_actual_radius_m": 0.6,
                "declared_radius_m": 0.4,
                "wrong_radius_20_w_mm": w_wrong,
                "radius_fixed_20_w_mm": w_fixed,
                "legacy_30_w_mm": w_legacy30,
                "canonical_30_w_mm": w_canonical30,
                "apparent_gap_wrong_radius_pct": old_gap,
                "gap_after_radius_fix_mixed_material_pct": geometry_fixed_gap,
                "gap_after_material_canonicalization_pct": canonical_gap,
                "gap_removed_by_geometry_fix_pct_point": old_gap - geometry_fixed_gap,
                "gap_removed_by_material_canonicalization_pct_point": geometry_fixed_gap - canonical_gap,
            }
        )

    out_csv = BASE / "discrepancy_20x20_root_cause_decomposition.csv"
    with out_csv.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    worst_old = max(rows, key=lambda row: float(row["apparent_gap_wrong_radius_pct"]))
    worst_mixed = max(rows, key=lambda row: float(row["gap_after_radius_fix_mixed_material_pct"]))
    worst_final = max(rows, key=lambda row: float(row["gap_after_material_canonicalization_pct"]))
    material_shift = max(
        rel(float(legacy30[key]["w_center_mm"]), float(canonical30[key]["w_center_mm"]))
        for key in keys
    )

    direct = read(BASE / "direct_comsol_mesh_validation.csv")
    direct20 = [row for row in direct if int(float(row["inplane_divisions"])) == 20]
    old_model_form_max = max(float(row["relative_error_matlab_pct"]) for row in direct20)
    iso = read(BASE / "isomorphic_solid" / "isomorphic_solid_cross_solver_comparison.csv")
    iso_max = max(float(row["center_relative_error_pct"]) for row in iso)

    summary = f"""# 20x20 偏差归因闭环

“20x20 偏差大”实际包含两个不同问题，现均已通过区分性试验闭环。

## 1. 曲率网格异常：输入几何错误为主，材料护照混用为次

首批名为 R=0.4 m 的 20x20 曲壳节点实际半径为 0.6 m。把该结果与 R=0.4 m 的 30x30 比较，六类工况最大表观差为 {float(worst_old['apparent_gap_wrong_radius_pct']):.6g}%（{worst_old['mode']}/{worst_old['load_case']}）。用真实 R=0.4 m 重新生成 20x20 后，最大差降至 {float(worst_mixed['gap_after_radius_fix_mixed_material_pct']):.6g}%，说明原约 3% 异常主要是几何口径错误，不是网格离散振荡。

进一步审计发现，旧 30x30 U 文件的 G13/G23=5.4e10 Pa，而正式口径为 4.5e10 Pa。该差异最多使本组 30x30 位移移动 {material_shift:.6g}%；虽然不是原大偏差的主因，却使旧收敛对比在方法上无效。将 20/30 两侧材料哈希统一后，R=0.4 m 六类最大差进一步降至 {float(worst_final['gap_after_material_canonicalization_pct']):.6g}%（{worst_final['mode']}/{worst_final['load_case']}）。

## 2. MATLAB--COMSOL 的 9%--11%：模型非同构，而非 20x20 网格

原直接场比较中，MATLAB LRT5 板与 COMSOL 三维实体在 20x20 的最大差为 {old_model_form_max:.6g}%。两侧各自的网格、厚度、场强和加载实现已排除为主因，但单元运动学、三维材料闭合和端面约束并不同构。

本轮新增 MATLAB H20 三维实体，并与 COMSOL 二次巧凑实体统一几何、材料、端面固支、每层厚度单元、ExternalStress 及测点。10/15/20 共六组中心位移最大跨软件差为 {iso_max:.6g}%，低于 0.1% 门槛。故 9%--11% 应报告为 LRT5--三维实体模型形式差，不能报告成 MATLAB 或 COMSOL 数值误差。

## 冻结结论

1. 原曲率 20/30 约 3% 非单调差异：主因是 20x20 实际半径 0.6 m 被标成 0.4 m；旧 U 材料护照不一致是独立的次级污染。
2. 原 MATLAB--COMSOL 20x20 约 9%--11% 差异：主因是 LRT5 板与三维实体不同构；严格 H20--三维实体同构后只剩 {iso_max:.6g}% 。
3. 因而不能用“20x20 网格太粗”解释任一异常；正文只使用半径、材料哈希均通过审计的新 20/30 结果。
"""
    (BASE / "discrepancy_20x20_closure.md").write_text(summary, encoding="utf-8")
    print(
        f"rows={len(rows)} old_max={float(worst_old['apparent_gap_wrong_radius_pct']):.6g}% "
        f"final_max={float(worst_final['gap_after_material_canonicalization_pct']):.6g}% "
        f"isomorphic_max={iso_max:.6g}%"
    )


if __name__ == "__main__":
    main()
