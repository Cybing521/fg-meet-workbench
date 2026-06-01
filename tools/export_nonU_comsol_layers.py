#!/usr/bin/env python3
"""Export non-U distribution (V, X) COMSOL layer CSVs for validation.

Generates 10-layer material CSV files for V and X distributions at Vf0.6
to validate that the FG material model works beyond U-type.

Usage:
    python export_nonU_comsol_layers.py
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

WORKBENCH = Path(__file__).resolve().parents[1]
EXPORT_DIR = WORKBENCH / "comsol" / "export" / "nonU"

sys.path.insert(0, str(WORKBENCH / "tools"))
from generate_cases import get_bto_cfo, fg_vf, MeetProps

COLS = [
    "layer", "E1", "E2", "v12", "v23", "G12", "G13", "G23",
    "d31", "d32", "angle", "hE", "q31", "q32", "g33", "k33", "r33",
    "A1", "A2", "PyroE", "PyroM", "Cv", "HC", "Density", "zC1", "zC2",
]

# Validation cases: V and X at Vf0.6 (same as the U baseline already validated)
VALIDATION_CASES = [
    ("V", 0.6),
    ("X", 0.6),
]


def build_layers_csv(fg_mode: str, vf0: float, n_layer: int = 10,
                     h: float = 6e-3) -> list[list]:
    bto, cfo = get_bto_cfo()
    dz = h / n_layer
    rows = []
    for k in range(1, n_layer + 1):
        z1 = -h / 2 + (k - 1) * dz
        z2 = -h / 2 + k * dz
        zmid = 0.5 * (z1 + z2)
        vf = fg_vf(zmid, h, vf0, fg_mode)
        props = bto.mix(cfo, vf)
        row = [k, props.E1, props.E2, props.v12, props.v23,
               props.G12, props.G13, props.G23,
               props.d31, props.d32, props.angle, props.hE,
               props.q31, props.q32, props.g33, props.k33, props.r33,
               props.A1, props.A2, props.PyroE, props.PyroM,
               props.Cv, props.HC, props.Density, z1, z2]
        rows.append(row)
    return rows


def export_case(fg_mode: str, vf0: float) -> Path:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"FG_{fg_mode}_Vf{vf0:.1f}_layers.csv"
    out = EXPORT_DIR / filename

    rows = build_layers_csv(fg_mode, vf0)
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(COLS)
        for row in rows:
            w.writerow(row)

    print(f"  Exported: {out.name} ({len(rows)} layers)")
    return out


def main() -> None:
    print("Exporting non-U distribution COMSOL layer CSVs:\n")
    for fg_mode, vf0 in VALIDATION_CASES:
        export_case(fg_mode, vf0)
    print(f"\nDone. Files in: {EXPORT_DIR}")


if __name__ == "__main__":
    main()
