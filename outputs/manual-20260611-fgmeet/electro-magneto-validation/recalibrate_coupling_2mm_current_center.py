from __future__ import annotations

import csv
import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
WORK_DIR = Path(__file__).resolve().parent
MAT_READER = ROOT / "outputs" / "manual-20260611-fgmeet" / "qian-force-displacement" / "extract_mat_fig_curves.py"
RESULTS_STATIC = ROOT / "output" / "results_static.csv"
OLD_ELASTIC_PROBE = (
    ROOT
    / "output"
    / "static_elastic_coupling_2mm_Thermal_CFFF_U_Vf0_6_30x30_10layer_probe_elastic.mat"
)
OUT_CSV = WORK_DIR / "current_coupling_2mm_recalibrated.csv"


def load_mat_reader():
    spec = importlib.util.spec_from_file_location("extract_mat_fig_curves", MAT_READER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load MAT reader from {MAT_READER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_static_row(case_id: str, load_case: str) -> dict[str, str]:
    with RESULTS_STATIC.open(newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            if row["case_id"] == case_id and row["load_case"] == load_case:
                return row
    raise KeyError(f"Missing row: {case_id} / {load_case}")


def scale_to_abs_2mm(probe_driver: float, probe_w_mm: float) -> float:
    return probe_driver * 2.0 / abs(probe_w_mm)


def main() -> None:
    elastic = read_static_row("U_Vf60_elastic", "elastic")
    electro = read_static_row("U_Vf60_electro", "electro")
    magneto = read_static_row("U_Vf60_magneto", "magneto")

    probe_load = float(elastic["load_scale"])
    probe_volt = float(electro["volt"])
    probe_magnetic = float(magneto["magnetic"])
    probe_w_mechanical = float(elastic["w_center_mm"])
    probe_w_electro = float(electro["w_center_mm"])
    probe_w_magneto = float(magneto["w_center_mm"])

    target_load = scale_to_abs_2mm(probe_load, probe_w_mechanical)
    target_volt = scale_to_abs_2mm(probe_volt, probe_w_electro)
    target_magnetic = scale_to_abs_2mm(probe_magnetic, probe_w_magneto)

    mat_reader = load_mat_reader()
    old_probe = mat_reader.read_mat_file(OLD_ELASTIC_PROBE)["result"]
    old_probe_load = float(old_probe["loadScale"])
    old_probe_electric_span = float(old_probe["electric_span"])
    old_probe_magnetic_span = float(old_probe["magnetic_span"])
    sensor_scale = target_load / old_probe_load
    current_electric_span = old_probe_electric_span * sensor_scale
    current_magnetic_span = old_probe_magnetic_span * sensor_scale

    rows = [
        {
            "check_id": "force_to_w",
            "description": "mechanical load to 2 mm center deflection, corrected center extraction",
            "method": "linear_rescale_from_results_static",
            "driver_kind": "mechanical_load",
            "driver_value": target_load,
            "driver_unit": "load_scale",
            "probe_driver": probe_load,
            "probe_w_center_mm": probe_w_mechanical,
            "target_abs_w_mm": 2.0,
            "generated_value": "",
            "transfer_coefficient": "",
            "transfer_unit": "",
            "status": "current_internal",
            "notes": "replaces stale -83134.1788268267 load_scale from old coupling_validation_2mm.csv",
        },
        {
            "check_id": "E_to_w",
            "description": "electric potential to 2 mm center deflection, corrected center extraction",
            "method": "linear_rescale_from_results_static",
            "driver_kind": "electric_potential",
            "driver_value": target_volt,
            "driver_unit": "V",
            "probe_driver": probe_volt,
            "probe_w_center_mm": probe_w_electro,
            "target_abs_w_mm": 2.0,
            "generated_value": "",
            "transfer_coefficient": "",
            "transfer_unit": "",
            "status": "current_internal",
            "notes": "matches current_forward_actuation_scaling_U_Vf06.csv",
        },
        {
            "check_id": "M_to_w",
            "description": "magnetic potential to 2 mm center deflection, corrected center extraction",
            "method": "linear_rescale_from_results_static",
            "driver_kind": "magnetic_potential",
            "driver_value": target_magnetic,
            "driver_unit": "A",
            "probe_driver": probe_magnetic,
            "probe_w_center_mm": probe_w_magneto,
            "target_abs_w_mm": 2.0,
            "generated_value": "",
            "transfer_coefficient": "",
            "transfer_unit": "",
            "status": "current_internal",
            "notes": "matches current_forward_actuation_scaling_U_Vf06.csv",
        },
        {
            "check_id": "w_to_E",
            "description": "2 mm mechanical deflection to induced electric potential span",
            "method": "shen_sensor_mechanical_2mm_recalibrated",
            "driver_kind": "mechanical_load",
            "driver_value": target_load,
            "driver_unit": "load_scale",
            "probe_driver": old_probe_load,
            "probe_w_center_mm": probe_w_mechanical,
            "target_abs_w_mm": 2.0,
            "generated_value": current_electric_span,
            "transfer_coefficient": current_electric_span / 2.0,
            "transfer_unit": "electric_span/mm",
            "status": "matched_qian_code_rerun",
            "notes": "qian same-case rerun gives 658.585489735107 with layer-average thermal-response convention",
        },
        {
            "check_id": "w_to_M",
            "description": "2 mm mechanical deflection to induced magnetic potential span",
            "method": "shen_sensor_mechanical_2mm_recalibrated",
            "driver_kind": "mechanical_load",
            "driver_value": target_load,
            "driver_unit": "load_scale",
            "probe_driver": old_probe_load,
            "probe_w_center_mm": probe_w_mechanical,
            "target_abs_w_mm": 2.0,
            "generated_value": current_magnetic_span,
            "transfer_coefficient": current_magnetic_span / 2.0,
            "transfer_unit": "magnetic_span/mm",
            "status": "matched_qian_code_rerun",
            "notes": "qian same-case rerun gives 0.681570500460291 with layer-average thermal-response convention",
        },
    ]

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    print(f"target_load={target_load:.12g}")
    print(f"target_volt={target_volt:.12g}")
    print(f"target_magnetic={target_magnetic:.12g}")
    print(f"w_to_E_span={current_electric_span:.12g}")
    print(f"w_to_M_span={current_magnetic_span:.12g}")
    print(f"wrote {OUT_CSV}")


if __name__ == "__main__":
    main()
