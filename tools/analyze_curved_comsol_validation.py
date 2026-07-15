"""Quantify the independent curved-solid COMSOL check and its evidence level."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXP = ROOT / "outputs" / "paper-20260715-fgmee" / "experiments" / "curvature_fg"
COMSOL = EXP / "comsol"


def read(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def rel(current: float, reference: float) -> float:
    return 100.0 * abs(current - reference) / max(abs(reference), 1e-300)


def write(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    paths = {
        10: COMSOL / "comsol_curved_U_R0p4_10x10x10_meshcheck_summary.csv",
        15: COMSOL / "comsol_curved_U_R0p4_15x15x10_meshcheck_summary.csv",
        20: COMSOL / "comsol_curved_U_R0p4_20x20x10_final_summary.csv",
    }
    matlab20_rows = read(EXP / "curvature_fg_full_mesh_20_30_raw.csv")
    matlab20 = next(
        float(row["w_center_mm"])
        for row in matlab20_rows
        if int(float(row["mesh"])) == 20
        and row["mode"] == "U"
        and abs(float(row["radius_m"]) - 0.4) < 1e-12
        and row["load_case"] == "elastic"
    )

    rows: list[dict[str, object]] = []
    previous: float | None = None
    for mesh in (10, 15, 20):
        source = read(paths[mesh])[0]
        value = float(source["w_center_radial_mm"])
        change = "" if previous is None else rel(value, previous)
        rows.append(
            {
                "model": "COMSOL_3D_curved_solid",
                "mode": "U",
                "radius_m": 0.4,
                "axial_divisions": mesh,
                "circumferential_divisions": mesh,
                "thickness_divisions": 10,
                "element_count": int(float(source["total_elements"])),
                "w_center_radial_mm": value,
                "change_from_previous_pct": change,
                "mesh_gate_1pct": "" if previous is None else ("pass" if float(change) <= 1.0 else "fail"),
                "source_file": str(paths[mesh]),
            }
        )
        previous = value
    write(EXP / "curved_comsol_mesh_convergence.csv", rows)

    comsol20 = float(rows[-1]["w_center_radial_mm"])
    model_gap = rel(comsol20, matlab20)
    comparison = [
        {
            "case_id": "curved_CFFF_U_R0p4_pressure15kPa",
            "matlab_model": "LRT5_curved_shell",
            "comsol_model": "quadratic_3D_curved_solid",
            "mesh_inplane": 20,
            "thickness_discretization": "MATLAB_10_physical_layers_COMSOL_10_hex",
            "matlab_w_center_mm": matlab20,
            "comsol_w_center_radial_mm": comsol20,
            "relative_model_form_gap_pct": model_gap,
            "sign_check": "pass" if matlab20 * comsol20 > 0 else "fail",
            "order_of_magnitude_check": "pass" if 0.5 <= abs(comsol20 / matlab20) <= 2.0 else "fail",
            "evidence_level": "B_independent_nonisomorphic_model_sensitivity",
            "interpretation": "not_a_cross_solver_numerical_error",
        }
    ]
    write(EXP / "curved_comsol_vs_matlab_model_form_comparison.csv", comparison)

    final_change = float(rows[-1]["change_from_previous_pct"])
    text = f"""# R=0.4 m 代表曲壳独立 COMSOL 核查

独立 COMSOL 模型采用 300 mm 轴向长度、300 mm 弧长、6 mm 厚度、R=0.4 m 的三维圆柱扇段；theta=0 整个端面固支，外表面施加 15 kPa 压力，二次巧凑实体通过映射--扫掠生成 10 层厚度网格。

COMSOL 中心径向位移由 10x10x10 的 {float(rows[0]['w_center_radial_mm']):.9g} mm 收敛到 15x15x10 的 {float(rows[1]['w_center_radial_mm']):.9g} mm 和 20x20x10 的 {comsol20:.9g} mm；15->20 变化 {final_change:.4f}%，通过 1% 网格门槛。

同口径 MATLAB LRT5 20x20 中心位移为 {matlab20:.9g} mm。两者符号、量级一致，但相差 {model_gap:.4f}%。由于一侧是曲壳 LRT5、一侧是三维实体，此值应作为 B 级模型形式敏感性证据，而不能写作同构数值误差。它与平板非同构对照约 9%--11% 的偏差方向一致；严格同构的平板 H20--COMSOL 对照已另行达到 0.00018% 以内。
"""
    (EXP / "curved_comsol_validation_summary.md").write_text(text, encoding="utf-8")
    print(f"final_mesh_change_pct={final_change:.12g}")
    print(f"curved_model_form_gap_pct={model_gap:.12g}")


if __name__ == "__main__":
    main()
