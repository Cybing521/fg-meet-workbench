#!/usr/bin/env python3
"""Generate 10x10 dynamic pilot cases for FG-mode Newmark sweeps."""

from __future__ import annotations

import csv
import shutil
from pathlib import Path

from generate_cases import FG_MODES_FULL, build_layers, patch_material


ROOT = Path(__file__).resolve().parents[1]
BASE_TEMPLATE = ROOT / "matlab" / "meet-elastic-thermal" / "InputFile" / "Thermal_CFFFplate_0.6Vf-10x10-10layer.txt"
OUT_DIR = ROOT / "cases" / "dynamic_10x10"
MANIFEST = OUT_DIR / "manifest_dynamic_10x10_vf06.csv"


def case_name(mode: str) -> str:
    return f"Thermal_CFFF_{mode}_Vf0.6-10x10-10layer.txt"


def main() -> None:
    if not BASE_TEMPLATE.is_file():
        raise SystemExit(f"Missing base template: {BASE_TEMPLATE}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    rows: list[list[str]] = []
    for mode in FG_MODES_FULL:
        out = OUT_DIR / case_name(mode)
        shutil.copy2(BASE_TEMPLATE, out)
        material_rows = build_layers(10, 6e-3, 0.6, mode, 2)
        patch_material(out, material_rows, f"10x10 dynamic FG {mode} Vf0=0.6")
        rows.append([mode, "0.6", str(out.relative_to(ROOT)).replace("\\", "/")])
        print(f"Generated {out}")

    with MANIFEST.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["fg_mode", "vf0", "input_file"])
        writer.writerows(rows)
    print(f"Manifest: {MANIFEST}")


if __name__ == "__main__":
    main()
