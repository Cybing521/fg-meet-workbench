#!/usr/bin/env python3
"""Export porous FG-MEE layered materials to COMSOL CSV for validation.

Generates 10-layer material CSV files for COMSOL import, with porosity
correction applied. Supports batch export for representative validation cases.

Usage:
    # Export single case
    python export_porous_comsol_layers.py U 0.5 0.2 Even

    # Export default validation set (3 representative cases)
    python export_porous_comsol_layers.py --validation-set
"""

from __future__ import annotations

import csv
import math
import sys
from dataclasses import dataclass, fields
from pathlib import Path

WORKBENCH = Path(__file__).resolve().parents[1]
EXPORT_DIR = WORKBENCH / "comsol" / "export" / "porous"

# COMSOL CSV column headers
COLS = [
    "layer", "E1", "E2", "v12", "v23", "G12", "G13", "G23",
    "d31", "d32", "angle", "hE", "q31", "q32", "g33", "k33", "r33",
    "A1", "A2", "PyroE", "PyroM", "Cv", "HC", "Density", "zC1", "zC2",
]

# Validation representative cases
VALIDATION_CASES = [
    # (fg_mode, vf0, e0, porosity_mode_name, porosity_mode_int)
    ("U", 0.5, 0.2, "Even", 1),
    ("U", 0.5, 0.3, "Even", 1),
    ("X", 0.5, 0.2, "Even", 1),
]

POROSITY_MODE_MAP = {"Even": 1, "Uneven": 2, "LogUneven": 3}


@dataclass
class MeetProps:
    E1: float; E2: float; v12: float; v23: float
    G12: float; G13: float; G23: float
    d31: float; d32: float; angle: float; hE: float
    q31: float; q32: float; g33: float; k33: float; r33: float
    A1: float; A2: float; PyroE: float; PyroM: float
    Cv: float; HC: float; Density: float

    def mix(self, other: "MeetProps", vf: float) -> "MeetProps":
        d = {}
        for f in fields(self):
            d[f.name] = vf * getattr(self, f.name) + (1 - vf) * getattr(other, f.name)
        return MeetProps(**d)

    def apply_porosity(self, e0: float, poro_mode: int, z: float, h: float) -> "MeetProps":
        if e0 <= 0:
            return self
        if poro_mode == 1:  # Even
            factor = 1 - e0
        elif poro_mode == 2:  # Uneven
            factor = 1 - e0 * (1 - 2 * abs(z) / h)
        elif poro_mode == 3:  # LogUneven
            arg = max(1 - 2 * abs(z) / h, 1e-10)
            factor = max(1 - (e0 / 2) * math.log(1.0 / arg), 0.01)
        else:
            raise ValueError(f"Unknown porosity mode: {poro_mode}")
        corrected = {'E1','E2','v12','G12','G13','G23','d31','d32',
                     'q31','q32','g33','k33','r33','A1','A2',
                     'PyroE','PyroM','Cv','Density'}
        d = {}
        for f in fields(self):
            val = getattr(self, f.name)
            d[f.name] = val * factor if f.name in corrected else val
        return MeetProps(**d)


def get_bto_cfo() -> tuple[MeetProps, MeetProps]:
    cfo = MeetProps(
        E1=2.10e11, E2=2.10e11, v12=0.31, v23=0.0,
        G12=4.53e10, G13=4.53e10, G23=4.53e10,
        d31=0.0, d32=0.0, angle=0.0, hE=6.0e-4,
        q31=5.80e2, q32=5.80e2, g33=9.3e-11, k33=0.0, r33=1.57e-3,
        A1=1.8e6, A2=1.8e6, PyroE=0.0, PyroM=0.0,
        Cv=165.0, HC=1.0, Density=5300.0,
    )
    ref = MeetProps(
        E1=1.206e11, E2=1.206e11, v12=3.398e-01, v23=0.0,
        G12=4.500e10, G13=4.500e10, G23=4.500e10,
        d31=-5.404e-11, d32=-5.404e-11, angle=0.0, hE=6.0e-4,
        q31=4.947e1, q32=4.947e1, g33=9.203e-09, k33=1.755e-08, r33=7.536e-05,
        A1=2.356e06, A2=2.356e06, PyroE=2.492e-04, PyroM=5.900e-03,
        Cv=425.2232, HC=1.0, Density=5600.0,
    )
    vf_ref = 0.6
    bto_d = {}
    for f in fields(ref):
        bto_d[f.name] = (getattr(ref, f.name) - (1 - vf_ref) * getattr(cfo, f.name)) / vf_ref
    return MeetProps(**bto_d), cfo


def fg_vf(z: float, h: float, vf0: float, mode: str) -> float:
    zeta = z / h + 0.5
    abs_z = abs(z) / (h / 2)
    m = mode.upper()
    if m == "U":
        vf = vf0
    elif m == "X":
        vf = vf0 * abs_z
    else:
        raise ValueError(f"Unsupported FG mode for COMSOL export: {mode}")
    return max(0.0, min(1.0, vf))


def build_porous_layers_csv(fg_mode: str, vf0: float, e0: float,
                            poro_mode: int, n_layer: int = 10,
                            h: float = 6e-3) -> list[list]:
    """Build layer data rows for COMSOL CSV export."""
    bto, cfo = get_bto_cfo()
    dz = h / n_layer
    rows = []
    for k in range(1, n_layer + 1):
        z1 = -h / 2 + (k - 1) * dz
        z2 = -h / 2 + k * dz
        zmid = 0.5 * (z1 + z2)
        vf = fg_vf(zmid, h, vf0, fg_mode)
        props = bto.mix(cfo, vf)
        if e0 > 0:
            props = props.apply_porosity(e0, poro_mode, zmid, h)
        row = [k, props.E1, props.E2, props.v12, props.v23,
               props.G12, props.G13, props.G23,
               props.d31, props.d32, props.angle, props.hE,
               props.q31, props.q32, props.g33, props.k33, props.r33,
               props.A1, props.A2, props.PyroE, props.PyroM,
               props.Cv, props.HC, props.Density, z1, z2]
        rows.append(row)
    return rows


def export_case(fg_mode: str, vf0: float, e0: float, poro_name: str,
                poro_mode: int) -> Path:
    """Export a single porous case to COMSOL CSV."""
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    e0_tag = f"e{int(e0*100):02d}"
    filename = f"Porous_{fg_mode}_Vf{vf0:.1f}_{e0_tag}_{poro_name}_layers.csv"
    out = EXPORT_DIR / filename

    rows = build_porous_layers_csv(fg_mode, vf0, e0, poro_mode)
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(COLS)
        for row in rows:
            w.writerow(row)

    print(f"  Exported: {out.name} ({len(rows)} layers)")
    return out


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--validation-set":
        print("Exporting COMSOL validation set for porous cases:\n")
        for fg, vf0, e0, pname, pmode in VALIDATION_CASES:
            export_case(fg, vf0, e0, pname, pmode)
        print(f"\nDone. Files in: {EXPORT_DIR}")
        return

    if len(sys.argv) < 5:
        print("Usage:")
        print("  export_porous_comsol_layers.py <fg_mode> <vf0> <e0> <poro_name>")
        print("  export_porous_comsol_layers.py --validation-set")
        print("\nExamples:")
        print("  export_porous_comsol_layers.py U 0.5 0.2 Even")
        print("  export_porous_comsol_layers.py X 0.5 0.3 LogUneven")
        sys.exit(1)

    fg_mode = sys.argv[1]
    vf0 = float(sys.argv[2])
    e0 = float(sys.argv[3])
    poro_name = sys.argv[4]
    poro_mode = POROSITY_MODE_MAP.get(poro_name)
    if poro_mode is None:
        print(f"Error: Unknown porosity mode '{poro_name}'.")
        print(f"  Valid: {list(POROSITY_MODE_MAP.keys())}")
        sys.exit(1)

    export_case(fg_mode, vf0, e0, poro_name, poro_mode)


if __name__ == "__main__":
    main()
