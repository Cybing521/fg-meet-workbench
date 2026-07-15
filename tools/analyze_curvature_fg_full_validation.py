"""Finalize all-radius 20/30 curvature-gradient convergence and interaction tables."""

from __future__ import annotations

import csv
import math
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXP = ROOT / "outputs" / "paper-20260715-fgmee" / "experiments" / "curvature_fg"
MANIFEST = ROOT / "cases" / "curvature_fg" / "curvature_case_manifest.csv"
RADII = (1.0, 0.4, 0.3, 0.2)
MODES = ("U", "X")
LOADS = ("elastic", "electro", "magneto")


def read(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def rel(current: float, previous: float) -> float:
    return 100.0 * abs(current - previous) / max(abs(current), 1e-300)


def main() -> None:
    # Use the incremental 20/30 checkpoint as the authority so analysis stays
    # restart-safe even if MATLAB exits after the last solve but before writing
    # the convenience 10/20/30 convergence table.
    convergence = read(EXP / "curvature_fg_full_mesh_20_30_raw.csv")
    valid = [
        row for row in convergence
        if math.isfinite(float(row["radius_m"]))
        and any(abs(float(row["radius_m"]) - radius) < 1e-12 for radius in RADII)
    ]
    by_key = {
        (
            int(float(row["mesh"])), row["mode"],
            round(float(row["radius_m"]), 12), row["load_case"],
        ): row
        for row in valid
    }
    expected_case_rows = 2 * len(RADII) * len(MODES) * len(LOADS)
    if len(valid) != expected_case_rows or len(by_key) != expected_case_rows:
        raise RuntimeError(
            f"incomplete or duplicate 20/30 checkpoint: rows={len(valid)}, "
            f"unique={len(by_key)}, expected={expected_case_rows}"
        )

    dense = read(ROOT / "output" / "results_static.csv")
    flat: dict[tuple[str, str], float] = {}
    for row in dense:
        if row.get("vf0") == "0.6" and row.get("fg_mode") in MODES and row.get("load_case") in LOADS:
            flat[(row["fg_mode"], row["load_case"])] = abs(float(row["w_center_mm"]))
    missing_flat = [key for key in ((m, l) for m in MODES for l in LOADS) if key not in flat]
    if missing_flat:
        raise RuntimeError(f"missing flat references: {missing_flat}")

    final_rows: list[dict[str, object]] = []
    interaction_rows: list[dict[str, object]] = []
    radius_summary: list[dict[str, object]] = []
    for radius in RADII:
        radius_changes: list[float] = []
        for mode in MODES:
            for load_case in LOADS:
                r20 = by_key[(20, mode, round(radius, 12), load_case)]
                r30 = by_key[(30, mode, round(radius, 12), load_case)]
                w20 = float(r20["w_center_mm"])
                w30 = float(r30["w_center_mm"])
                change = rel(w30, w20)
                radius_changes.append(change)
                final_rows.append(
                    {
                        "mesh": 30,
                        "mode": mode,
                        "radius_m": radius,
                        "curvature_1pm": 1.0 / radius,
                        "load_case": load_case,
                        "w_center_mm": w30,
                        "w_20x20_mm": w20,
                        "w_change_20_to_30_pct": change,
                        "mesh_gate_0p5pct": "pass" if change <= 0.5 else "fail",
                        "mesh_gate_1pct": "pass" if change <= 1.0 else "fail",
                        "flat_30_abs_w_mm": flat[(mode, load_case)],
                        "curved_to_flat_abs_ratio": abs(w30) / flat[(mode, load_case)],
                        "material_passport": "canonical_cross_mesh_hash_verified",
                        "status": "completed_corrected_pyro",
                    }
                )
        for load_case in LOADS:
            u = next(
                row for row in final_rows
                if row["radius_m"] == radius and row["mode"] == "U"
                and row["load_case"] == load_case
            )
            x = next(
                row for row in final_rows
                if row["radius_m"] == radius and row["mode"] == "X"
                and row["load_case"] == load_case
            )
            interaction_pp = 100.0 * (
                float(x["curved_to_flat_abs_ratio"])
                - float(u["curved_to_flat_abs_ratio"])
            )
            bound = max(float(u["w_change_20_to_30_pct"]), float(x["w_change_20_to_30_pct"]))
            interaction_rows.append(
                {
                    "radius_m": radius,
                    "curvature_1pm": 1.0 / radius,
                    "load_case": load_case,
                    "U_curved_to_flat_ratio": u["curved_to_flat_abs_ratio"],
                    "X_curved_to_flat_ratio": x["curved_to_flat_abs_ratio"],
                    "gradient_curvature_interaction_pct_point": interaction_pp,
                    "max_20_to_30_mesh_change_pct": bound,
                    "interaction_to_mesh_change_ratio": abs(interaction_pp) / max(bound, 1e-300),
                    "resolved_above_3x_mesh_bound": "pass" if abs(interaction_pp) > 3.0 * bound else "fail",
                }
            )
        radius_summary.append(
            {
                "radius_m": radius,
                "curvature_1pm": 1.0 / radius,
                "number_of_30x30_cases": 6,
                "max_w_change_20_to_30_pct": max(radius_changes),
                "mean_w_change_20_to_30_pct": sum(radius_changes) / len(radius_changes),
                "all_cases_gate_0p5pct": "pass" if max(radius_changes) <= 0.5 else "fail",
                "all_cases_gate_1pct": "pass" if max(radius_changes) <= 1.0 else "fail",
            }
        )

    manifest = read(MANIFEST)
    manifest_valid = [row for row in manifest if int(float(row["mesh"])) in (10, 20, 30)]
    hash_counts = {
        mode: len({row["material_numeric_sha256"] for row in manifest_valid if row["mode"] == mode})
        for mode in MODES
    }
    radius_mismatches = sum(
        abs(float(row["radius_m"]) - float(row["actual_node_radius_m"])) > 1e-12
        for row in manifest_valid
    )
    if any(value != 1 for value in hash_counts.values()) or radius_mismatches:
        raise RuntimeError(
            f"case passport audit failed: hash_counts={hash_counts}, radius_mismatches={radius_mismatches}"
        )

    write(EXP / "curvature_fg_final_30x30_results.csv", final_rows)
    write(EXP / "curvature_fg_all_radius_interaction_30x30.csv", interaction_rows)
    write(EXP / "curvature_fg_all_radius_mesh_summary.csv", radius_summary)
    passport = [
        {
            "manifest_cases": len(manifest_valid),
            "U_unique_material_numeric_hashes": hash_counts["U"],
            "X_unique_material_numeric_hashes": hash_counts["X"],
            "radius_mismatch_count": radius_mismatches,
            "audit_status": "pass",
        }
    ]
    write(EXP / "curvature_fg_case_passport_audit.csv", passport)

    max_change = max(float(row["max_w_change_20_to_30_pct"]) for row in radius_summary)
    passed_1 = sum(row["all_cases_gate_1pct"] == "pass" for row in radius_summary)
    resolved = [row for row in interaction_rows if row["resolved_above_3x_mesh_bound"] == "pass"]
    text = f"""# 全半径曲率--梯度 20/30 网格复核

## 数据护照

共核对 {len(manifest_valid)} 个 10/20/30 网格曲壳输入文件。U、X 各自跨网格/跨半径仅有 1 个材料数值哈希，节点实际半径与声明半径不一致数为 {radius_mismatches}；旧 30 网格 G13/G23=5.4e10 的混入口径已排除。

## 网格完成度

R=1.0、0.4、0.3、0.2 m 的 U/X x 机械/电/磁共 24 个 20x20 和 24 个 30x30 正式工况均已完成。四个半径中有 {passed_1}/4 个半径的六类中心位移全部通过 1% 门槛；全表最大 20->30 变化为 {max_change:.6g}%。逐半径门槛见 curvature_fg_all_radius_mesh_summary.csv。

## 可用于正文的交互量

在 30x30 结果上，以各自平板 30x30 结果归一化，形成 4 个半径 x 3 类载荷的 U/X 曲率--梯度交互。共有 {len(resolved)}/{len(interaction_rows)} 个交互量高于 3 倍离散变化界，可作为已分辨机制信号；其余必须标注为未超过离散误差。

本结果替代旧的“仅 R=0.4 m 正式复核”表述；正文曲率主图可以使用全部四个半径的 30x30 点，并用 20->30 变化作为误差/可信度边界。
"""
    (EXP / "curvature_fg_full_validation_summary.md").write_text(text, encoding="utf-8")

    pass_0p5 = sum(row["all_cases_gate_0p5pct"] == "pass" for row in radius_summary)
    radius_tex = "\n".join(
        f"{float(row['radius_m']):.1f} & {float(row['curvature_1pm']):.1f} & "
        f"{float(row['max_w_change_20_to_30_pct']):.4f} & "
        f"{float(row['mean_w_change_20_to_30_pct']):.4f} & "
        f"{'通过' if row['all_cases_gate_1pct'] == 'pass' else '未通过'} \\\\"
        for row in radius_summary
    )
    load_labels = {"elastic": "机械", "electro": "电致", "magneto": "磁致"}
    interaction_tex = "\n".join(
        f"{float(row['radius_m']):.1f} & {load_labels[row['load_case']]} & "
        f"{float(row['gradient_curvature_interaction_pct_point']):.4f} & "
        f"{float(row['max_20_to_30_mesh_change_pct']):.4f} & "
        f"{float(row['interaction_to_mesh_change_ratio']):.1f} & "
        f"{'已分辨' if row['resolved_above_3x_mesh_bound'] == 'pass' else '未分辨'} \\\\"
        for row in interaction_rows
    )
    strongest = max(
        interaction_rows,
        key=lambda row: abs(float(row["gradient_curvature_interaction_pct_point"])),
    )
    electric_magnetic_differences = []
    for radius in RADII:
        electric = next(
            row for row in interaction_rows
            if row["radius_m"] == radius and row["load_case"] == "electro"
        )
        magnetic = next(
            row for row in interaction_rows
            if row["radius_m"] == radius and row["load_case"] == "magneto"
        )
        electric_magnetic_differences.append(
            abs(
                float(electric["gradient_curvature_interaction_pct_point"])
                - float(magnetic["gradient_curvature_interaction_pct_point"])
            )
        )
    pressure_resolved = sum(
        row["load_case"] == "elastic" and row["resolved_above_3x_mesh_bound"] == "pass"
        for row in interaction_rows
    )
    interaction_conclusion = (
        f"12 个半径--载荷交互中有 {len(resolved)} 个高于三倍离散界；"
        f"绝对值最大者位于 $R={float(strongest['radius_m']):.1f}$ m 的"
        f"{load_labels[strongest['load_case']]}工况，为 "
        f"{float(strongest['gradient_curvature_interaction_pct_point']):.4f} 个百分点。"
        f"同一半径电致与磁致交互的最大差仅为 "
        f"{max(electric_magnetic_differences):.4g} 个百分点，符合线性结构响应下的归一化一致性；"
        f"机械工况有 {pressure_resolved}/4 个半径达到已分辨标准。"
    )
    gate_conclusion = (
        f"四个半径中有 {passed_1}/4 个半径的六类中心位移全部通过 1\\% 门槛，"
        f"其中 {pass_0p5}/4 个也通过 0.5\\% 优先门槛；全表最大变化为 "
        f"{max_change:.6g}\\%。"
    )
    full_status = r"\pass" if passed_1 == len(RADII) else r"\conditional"
    macros = f"""% Auto-generated by tools/analyze_curvature_fg_full_validation.py
\\newcommand{{\\MaxCurvatureChange}}{{{max_change:.6g}}}
\\newcommand{{\\CurvatureGateConclusion}}{{{gate_conclusion}}}
\\newcommand{{\\FullRadiusStatus}}{{{full_status}}}
\\newcommand{{\\InteractionConclusion}}{{{interaction_conclusion}}}
\\newcommand{{\\RadiusSummaryRows}}{{%
{radius_tex}
}}
\\newcommand{{\\InteractionRows}}{{%
{interaction_tex}
}}
"""
    (EXP / "curvature_fg_report_macros.tex").write_text(macros, encoding="utf-8")
    print(f"final_30x30_rows={len(final_rows)}")
    print(f"max_20_to_30_change_pct={max_change:.12g}")
    print(f"resolved_interactions={len(resolved)}/{len(interaction_rows)}")


if __name__ == "__main__":
    main()
