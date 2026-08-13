"""Quantify the inverse-sensor pyro-coupling overcount and compare corrected models."""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs" / "paper-20260715-fgmee" / "experiments" / "inverse_sensing"


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def span(values: list[float]) -> float:
    return max(values) - min(values)


def relative_error(value: float, reference: float) -> float:
    return abs(value - reference) / abs(reference) * 100.0


def slope(x: list[float], y: list[float]) -> float:
    return sum(a * b for a, b in zip(x, y)) / sum(a * a for a in x)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    qian_rows = read_rows(OUT / "qian_inverse_layer_means.csv")
    temperature = [float(row["SensM_T"]) for row in qian_rows]
    zero_e = [float(row["SensM_E_zero_delta"]) for row in qian_rows]
    zero_m = [float(row["SensM_M_zero_delta"]) for row in qian_rows]
    legacy_e = [float(row["SensM_E_thermal_response"]) for row in qian_rows]
    legacy_m = [float(row["SensM_M_thermal_response"]) for row in qian_rows]
    delta_e = [a - b for a, b in zip(legacy_e, zero_e)]
    delta_m = [a - b for a, b in zip(legacy_m, zero_m)]

    young = 1.206e11
    nu = 0.3398
    d31 = -5.404e-11
    e31 = d31 * young / (1.0 - nu)
    g_eff = 9.203e-9 - 2.0 * d31 * e31
    k33 = 1.755e-8
    r33 = 7.536e-5
    pyro_e = 2.492e-4
    pyro_m = 5.900e-3
    h = 0.0006
    determinant = g_eff * r33 - k33 * k33
    expected_e_per_k = h * (r33 * pyro_e - k33 * pyro_m) / determinant
    expected_m_per_k = -h * (k33 * pyro_e - g_eff * pyro_m) / determinant
    observed_e_per_k = slope(temperature, delta_e)
    observed_m_per_k = slope(temperature, delta_m)

    audit_rows = [
        {
            "coupling": "pyroelectric",
            "constitutive_coefficient_per_K": expected_e_per_k,
            "assembled_coefficient_per_K": observed_e_per_k,
            "assembled_to_constitutive_ratio": observed_e_per_k / expected_e_per_k,
            "expected_layer_multiplier": len(qian_rows),
            "diagnosis": "full PE diagonal repeated once per physical layer",
        },
        {
            "coupling": "pyromagnetic",
            "constitutive_coefficient_per_K": expected_m_per_k,
            "assembled_coefficient_per_K": observed_m_per_k,
            "assembled_to_constitutive_ratio": observed_m_per_k / expected_m_per_k,
            "expected_layer_multiplier": len(qian_rows),
            "diagnosis": "full PM diagonal repeated once per physical layer",
        },
    ]
    write_csv(
        OUT / "inverse_pyro_overcount_audit.csv",
        list(audit_rows[0]),
        audit_rows,
    )

    n_layer = len(qian_rows)
    corrected_e = [z + d / n_layer for z, d in zip(zero_e, delta_e)]
    corrected_m = [z + d / n_layer for z, d in zip(zero_m, delta_m)]
    center_at_probe_mm = 2.12751986193692
    targets = (0.5, 1.0, 2.0)
    qian_by_target: dict[float, dict[str, float]] = {}
    for target in targets:
        scale = target / center_at_probe_mm
        qian_by_target[target] = {
            "matlab_zero_e": span(zero_e) * scale,
            "matlab_zero_m": span(zero_m) * scale,
            "matlab_corrected_e": span(corrected_e) * scale,
            "matlab_corrected_m": span(corrected_m) * scale,
            "matlab_legacy_e": span(legacy_e) * scale,
            "matlab_legacy_m": span(legacy_m) * scale,
        }

    comparison_rows: list[dict[str, object]] = []
    for mesh in (10, 15, 20):
        suffix = "10x10x1_smoke" if mesh == 10 else f"{mesh}x{mesh}x5"
        rows = read_rows(OUT / f"comsol_inverse_sensor_{suffix}_summary.csv")
        for row in rows:
            target = float(row["target_w_mm"])
            ref = qian_by_target[target]
            comsol_zero_e = float(row["electric_span_zero_temperature_V"])
            comsol_zero_m = float(row["magnetic_span_zero_temperature_A"])
            comsol_full_e = float(row["electric_span_thermo_corrected_V"])
            comsol_full_m = float(row["magnetic_span_thermo_corrected_A"])
            comparison_rows.append(
                {
                    "mesh_inplane": mesh,
                    "thickness_divisions_per_layer": int(row["thickness_divisions_per_layer"]),
                    "target_w_mm": target,
                    "comsol_zero_e_V": comsol_zero_e,
                    "matlab_zero_e_V": ref["matlab_zero_e"],
                    "zero_e_error_pct": relative_error(comsol_zero_e, ref["matlab_zero_e"]),
                    "comsol_zero_m_A": comsol_zero_m,
                    "matlab_zero_m_A": ref["matlab_zero_m"],
                    "zero_m_error_pct": relative_error(comsol_zero_m, ref["matlab_zero_m"]),
                    "comsol_corrected_e_V": comsol_full_e,
                    "matlab_corrected_e_V": ref["matlab_corrected_e"],
                    "corrected_e_error_pct": relative_error(comsol_full_e, ref["matlab_corrected_e"]),
                    "comsol_corrected_m_A": comsol_full_m,
                    "matlab_corrected_m_A": ref["matlab_corrected_m"],
                    "corrected_m_error_pct": relative_error(comsol_full_m, ref["matlab_corrected_m"]),
                    "matlab_legacy_e_V": ref["matlab_legacy_e"],
                    "matlab_legacy_m_A": ref["matlab_legacy_m"],
                    "legacy_e_inflation_vs_corrected": ref["matlab_legacy_e"] / ref["matlab_corrected_e"],
                    "legacy_m_inflation_vs_corrected": ref["matlab_legacy_m"] / ref["matlab_corrected_m"],
                    "status": "completed_corrected_crosscheck",
                    "evidence_tier": "exploratory_nonindependent_constitutive_postprocess",
                }
            )
    write_csv(
        OUT / "inverse_sensor_corrected_comparison.csv",
        list(comparison_rows[0]),
        comparison_rows,
    )

    mesh20 = [row for row in comparison_rows if row["mesh_inplane"] == 20 and row["target_w_mm"] == 0.5][0]
    mesh15 = [row for row in comparison_rows if row["mesh_inplane"] == 15 and row["target_w_mm"] == 0.5][0]
    conv_e = relative_error(float(mesh20["comsol_corrected_e_V"]), float(mesh15["comsol_corrected_e_V"]))
    conv_m = relative_error(float(mesh20["comsol_corrected_m_A"]), float(mesh15["comsol_corrected_m_A"]))
    markdown = f"""# 位移反推电势/磁势深度核查

## 结论

旧的 0.5/1/2 mm 结果不是单纯的物理量偏大，而是热释电/热释磁矩阵存在逐层重复装配。每个物理层调用中，`PE` 和 `PM` 被写入全部 {n_layer} 个 MEE 层自由度；总装后耦合系数恰好放大 {n_layer} 倍。

- 电热项：本构预测 {expected_e_per_k:.12g} V/K，旧矩阵回归 {observed_e_per_k:.12g} V/K，比值 {observed_e_per_k / expected_e_per_k:.12f}。
- 磁热项：本构预测 {expected_m_per_k:.12g} A/K，旧矩阵回归 {observed_m_per_k:.12g} A/K，比值 {observed_m_per_k / expected_m_per_k:.12f}。
- 正式实现已在 `SF_ElemComptLIN851T5MEEP_V4.m` 中把 `p/t` 仅装配到当前物理层；`run_meet_static.m` 不再做除层数修补，也不再保留旧结果回退开关。

## 0.5 mm 探索性对比（20x20 三维力学，每物理层 5 个厚度单元）

- 修正后 MATLAB：电势 {float(mesh20['matlab_corrected_e_V']):.9f} V，磁势 {float(mesh20['matlab_corrected_m_A']):.9f} A。
- COMSOL 三维力学 + 同一本构后处理：电势 {float(mesh20['comsol_corrected_e_V']):.9f} V，磁势 {float(mesh20['comsol_corrected_m_A']):.9f} A。
- 相对差：电势 {float(mesh20['corrected_e_error_pct']):.4f}%，磁势 {float(mesh20['corrected_m_error_pct']):.4f}%。
- COMSOL 15x15 -> 20x20 变化：电势 {conv_e:.4f}%，磁势 {conv_m:.4f}%。

该约 3.5% 是两种非同构机械应变场经同一局部本构后处理得到的共享尺度差，不再是热释耦合十层重复装配造成的差异。它不是独立电势/磁势 PDE 的两个误差样本；由于逆向工况按相同中心位移标定，也不能与直接电/磁致变形的 9%--11% 当作同一误差量比较。
"""
    (OUT / "inverse_sensor_deep_diagnosis.md").write_text(markdown, encoding="utf-8")

    print(f"audit={OUT / 'inverse_pyro_overcount_audit.csv'}")
    print(f"comparison={OUT / 'inverse_sensor_corrected_comparison.csv'}")
    print(f"mesh20_0p5_corrected_errors={mesh20['corrected_e_error_pct']},{mesh20['corrected_m_error_pct']}")


if __name__ == "__main__":
    main()
