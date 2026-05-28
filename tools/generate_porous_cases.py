#!/usr/bin/env python3
"""Generate porous FG-MEE input files for Phase 6 parametric study.

Design space: 2 FG modes (U, X) × 5 e0 (0, 0.1, 0.2, 0.3, 0.4) × 3 porosity modes × 5 Vf0
Total: 150 cases (including e0=0 baselines)
"""

from __future__ import annotations

import csv
import math
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

WORKBENCH = Path(__file__).resolve().parents[1]
TEMPLATE = WORKBENCH / "templates" / "Thermal_CFFFplate_30x30_10layer_template.txt"
CASES_DIR = WORKBENCH / "cases" / "porous"

# Design space
FG_MODES = ("U", "X")
E0_VALUES = (0.0, 0.1, 0.2, 0.3, 0.4)
POROSITY_MODES = (1, 2, 3)  # Even, Uneven, Log-uneven
VF0_VALUES = (0.1, 0.3, 0.5, 0.7, 0.9)
POROSITY_MODE_NAMES = {1: "Even", 2: "Uneven", 3: "LogUneven"}


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
        for k in self.__dataclass_fields__:
            d[k] = vf * getattr(self, k) + (1 - vf) * getattr(other, k)
        return MeetProps(**d)

    def apply_porosity(self, e0: float, poro_mode: int, z: float, h: float) -> "MeetProps":
        """Apply porosity correction and return new MeetProps."""
        if e0 <= 0:
            return self
        abs_z_over_h = abs(z) / h
        if poro_mode == 1:  # Even
            factor = 1 - e0
        elif poro_mode == 2:  # Uneven (center-rich)
            factor = 1 - e0 * (1 - 2 * abs(z) / h)
        elif poro_mode == 3:  # Log-uneven
            arg = max(1 - 2 * abs(z) / h, 1e-10)
            factor = 1 - (e0 / 2) * math.log(1.0 / arg)
            factor = max(factor, 0.01)
        else:
            raise ValueError(f"Unknown porosity mode: {poro_mode}")

        d = {}
        # Fields that get porosity correction
        corrected = {'E1','E2','v12','G12','G13','G23','d31','d32',
                     'q31','q32','g33','k33','r33','A1','A2',
                     'PyroE','PyroM','Cv','Density'}
        for k in self.__dataclass_fields__:
            val = getattr(self, k)
            if k in corrected:
                d[k] = val * factor
            else:
                d[k] = val
        return MeetProps(**d)

    def format_row(self, layer: int, z1: float, z2: float, is_smt: int = 2) -> str:
        return (
            f"{layer}\t{self.E1:.3E}\t{self.E2:.3E}\t{self.v12:.3E}\t{self.v23:.3E}\t"
            f"{self.G12:.3E}\t{self.G13:.3E}\t{self.G23:.3E}\t{self.d31:.3E}\t{self.d32:.3E}\t"
            f"{self.angle:.3E}\t{self.hE:.3E}\t{self.q31:.3E}\t{self.q32:.3E}\t{self.g33:.3E}\t"
            f"{self.k33:.3E}\t{self.r33:.3E}\t{self.A1:.3E}\t{self.A2:.3E}\t{self.PyroE:.3E}\t"
            f"{self.PyroM:.3E}\t{self.Cv:.3E}\t{self.HC:.3E}\t{self.Density:.3E}\t"
            f"{z1:.3E}\t{z2:.3E}\t{is_smt}"
        )


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
    for k in ref.__dataclass_fields__:
        bto_d[k] = (getattr(ref, k) - (1 - vf_ref) * getattr(cfo, k)) / vf_ref
    return MeetProps(**bto_d), cfo


def fg_vf(z: float, h: float, vf0: float, mode: str, power_n: int = 2) -> float:
    zeta = z / h + 0.5
    abs_z = abs(z) / (h / 2)
    m = mode.upper()
    if m == "U":
        vf = vf0
    elif m == "V":
        vf = vf0 * zeta
    elif m == "X":
        vf = vf0 * abs_z
    elif m == "O":
        vf = vf0 * (2 - abs_z)
    elif m == "P":
        vf = vf0 * (zeta**power_n)
    else:
        raise ValueError(mode)
    return max(0.0, min(1.0, vf))


def build_porous_layers(n_layer: int, h: float, vf0: float, fg_mode: str,
                        e0: float, poro_mode: int, power_n: int = 2) -> list[str]:
    bto, cfo = get_bto_cfo()
    dz = h / n_layer
    rows = []
    for k in range(1, n_layer + 1):
        z1 = -h / 2 + (k - 1) * dz
        z2 = -h / 2 + k * dz
        zmid = 0.5 * (z1 + z2)
        vf = fg_vf(zmid, h, vf0, fg_mode, power_n)
        props = bto.mix(cfo, vf)
        # Apply porosity correction
        if e0 > 0:
            props = props.apply_porosity(e0, poro_mode, zmid, h)
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


def case_name(fg_mode: str, vf0: float, e0: float, poro_mode: int) -> str:
    pname = POROSITY_MODE_NAMES[poro_mode]
    e0_tag = f"e{int(e0*100):02d}"
    return f"Porous_CFFF_{fg_mode}_Vf{vf0:.1f}_{e0_tag}_{pname}-30x30-10layer.txt"


def generate_case(fg_mode: str, vf0: float, e0: float, poro_mode: int) -> Path:
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    name = case_name(fg_mode, vf0, e0, poro_mode)
    out = CASES_DIR / name
    shutil.copy2(TEMPLATE, out)
    rows = build_porous_layers(10, 6e-3, vf0, fg_mode, e0, poro_mode)
    patch_material(out, rows)
    return out


def main() -> None:
    if not TEMPLATE.is_file():
        raise SystemExit(f"Missing template: {TEMPLATE}")

    manifest_rows = []
    count = 0

    for fg_mode in FG_MODES:
        for e0 in E0_VALUES:
            for poro_mode in POROSITY_MODES:
                # Skip non-Even modes when e0=0 (they're all identical)
                if e0 == 0 and poro_mode != 1:
                    continue
                for vf0 in VF0_VALUES:
                    name = case_name(fg_mode, vf0, e0, poro_mode)
                    p = generate_case(fg_mode, vf0, e0, poro_mode)
                    rel_path = f"cases/porous/{name}"
                    manifest_rows.append((fg_mode, vf0, e0,
                                         POROSITY_MODE_NAMES[poro_mode],
                                         poro_mode, rel_path))
                    count += 1
                    print(f"[{count:3d}] {name}")

    # Write manifest
    manifest_path = CASES_DIR / "manifest_porous.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["fg_mode", "vf0", "e0", "porosity_name",
                    "porosity_mode", "input_file"])
        w.writerows(manifest_rows)

    print(f"\nGenerated {count} porous cases")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
