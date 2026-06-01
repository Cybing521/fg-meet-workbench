#!/usr/bin/env python3
"""Generate CFCF boundary condition input files for FG-MEE plate.

Creates 30x30 10-layer input files with CFCF boundary conditions
for U and X distributions at 5 volume fractions.

Usage:
    python generate_cfcf_cases.py
"""

from __future__ import annotations

import csv
import re
import shutil
from pathlib import Path

WORKBENCH = Path(__file__).resolve().parents[1]
CFCF_TEMPLATE = WORKBENCH / "matlab" / "meet-elastic-thermal" / "InputFile" / "Thermal_CFCFplate_0.6Vf-30x30-10layer.txt"
CASES_DIR = WORKBENCH / "cases" / "cfcf"

# Design space: U and X at 5 volume fractions
FG_MODES = ("U", "X")
VF0_VALUES = (0.1, 0.3, 0.5, 0.7, 0.9)

# Import material functions from generate_cases.py
import sys
sys.path.insert(0, str(WORKBENCH / "tools"))
from generate_cases import get_bto_cfo, fg_vf, MeetProps


def build_layers(n_layer: int, h: float, vf0: float, mode: str) -> list[str]:
    bto, cfo = get_bto_cfo()
    dz = h / n_layer
    rows = []
    for k in range(1, n_layer + 1):
        z1 = -h / 2 + (k - 1) * dz
        z2 = -h / 2 + k * dz
        zmid = 0.5 * (z1 + z2)
        vf = fg_vf(zmid, h, vf0, mode)
        props = bto.mix(cfo, vf)
        rows.append(props.format_row(k, z1, z2))
    return rows


def patch_material(path: Path, layer_rows: list[str]) -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    block = "MATERIAL START\n"
    block += "\n".join(layer_rows) + "\nMATERIAL END"
    new_text, n = re.subn(
        r"MATERIAL START.*?MATERIAL END", block, text, count=1, flags=re.DOTALL,
    )
    if n != 1:
        raise RuntimeError(f"MATERIAL block not found in {path}")
    path.write_text(new_text, encoding="utf-8")


def case_name(mode: str, vf0: float) -> str:
    return f"Thermal_CFCF_{mode}_Vf{vf0:.1f}-30x30-10layer.txt"


def generate(vf0: float, mode: str) -> Path:
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    name = case_name(mode, vf0)
    out = CASES_DIR / name
    shutil.copy2(CFCF_TEMPLATE, out)
    rows = build_layers(10, 6e-3, vf0, mode)
    patch_material(out, rows)
    return out


def main() -> None:
    if not CFCF_TEMPLATE.is_file():
        raise SystemExit(
            f"Missing CFCF template: {CFCF_TEMPLATE}\n"
            "Need Thermal_CFCFplate_0.6Vf-30x30-10layer.txt in InputFile/"
        )

    manifest_rows = []
    count = 0

    for mode in FG_MODES:
        for vf0 in VF0_VALUES:
            name = case_name(mode, vf0)
            p = generate(vf0, mode)
            rel_path = f"cases/cfcf/{name}"
            manifest_rows.append((mode, vf0, rel_path))
            count += 1
            print(f"[{count:2d}] {name}")

    # Write manifest
    manifest_path = CASES_DIR / "manifest_cfcf.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["fg_mode", "vf0", "input_file"])
        w.writerows(manifest_rows)

    print(f"\nGenerated {count} CFCF cases")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
