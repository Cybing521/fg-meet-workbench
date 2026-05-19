#!/usr/bin/env python3
"""Generate FG thermal MEET input files (no MATLAB required)."""

from __future__ import annotations

import csv
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

WORKBENCH = Path(__file__).resolve().parents[1]
TEMPLATE = WORKBENCH / "templates" / "Thermal_CFFFplate_30x30_10layer_template.txt"
CASES_DIR = WORKBENCH / "cases"
REF_QIAN = (
    WORKBENCH.parent
    / "钱沈云论文及相关代码/双向耦合程序-new/双向耦合程序-new/MEET-elastic-thermal/InputFile/Thermal_CFFFplate_0.6Vf-30x30-10layer.txt"
)


@dataclass
class MeetProps:
    E1: float
    E2: float
    v12: float
    v23: float
    G12: float
    G13: float
    G23: float
    d31: float
    d32: float
    angle: float
    hE: float
    q31: float
    q32: float
    g33: float
    k33: float
    r33: float
    A1: float
    A2: float
    PyroE: float
    PyroM: float
    Cv: float
    HC: float
    Density: float

    def mix(self, other: "MeetProps", vf: float) -> "MeetProps":
        d = {}
        for k in self.__dataclass_fields__:
            d[k] = vf * getattr(self, k) + (1 - vf) * getattr(other, k)
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


def patch_material(path: Path, layer_rows: list[str], comment: str = "") -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    block = "MATERIAL START\n"
    if comment:
        block += f"% {comment}\n"
    block += "\n".join(layer_rows) + "\nMATERIAL END"
    new_text, n = re.subn(
        r"MATERIAL START.*?MATERIAL END",
        block,
        text,
        count=1,
        flags=re.DOTALL,
    )
    if n != 1:
        raise RuntimeError(f"MATERIAL block not found in {path}")
    path.write_text(new_text, encoding="utf-8")


def read_material_rows(path: Path) -> list[list[float]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"MATERIAL START(.*?)MATERIAL END", text, re.DOTALL)
    if not m:
        return []
    rows = []
    for line in m.group(1).splitlines():
        line = line.strip()
        if line and not line.startswith("%") and line[0].isdigit():
            rows.append([float(x) for x in line.split()])
    return rows


def max_rel_diff(a: Path, b: Path) -> float:
    ga, gb = read_material_rows(a), read_material_rows(b)
    mx = 0.0
    for ra, rb in zip(ga, gb):
        for x, y in zip(ra[1:], rb[1:]):
            mx = max(mx, abs(x - y) / max(abs(y), 1e-30))
    return mx


def generate(vf0: float, mode: str, out_name: str) -> Path:
    CASES_DIR.mkdir(parents=True, exist_ok=True)
    out = CASES_DIR / out_name
    shutil.copy2(TEMPLATE, out)
    rows = build_layers(10, 6e-3, vf0, mode)
    patch_material(out, rows, f"FG {mode} Vf0={vf0:.2f} auto-generated")
    return out


def main() -> None:
    if not TEMPLATE.is_file():
        raise SystemExit(f"Missing template: {TEMPLATE}")

    manifest = []
    for mode in ("U", "X", "V"):
        for vf0 in (0.3, 0.5, 0.7):
            name = f"Thermal_CFFF_{mode}_Vf{vf0:.1f}-30x30-10layer.txt"
            p = generate(vf0, mode, name)
            manifest.append((mode, vf0, str(p)))
            print(f"Generated {p}")

    ref_out = generate(0.6, "U", "Thermal_CFFF_U_Vf0.6-30x30-10layer.txt")
    manifest.append(("U", 0.6, str(ref_out)))

    if REF_QIAN.is_file():
        diff = max_rel_diff(ref_out, REF_QIAN)
        print(f"\nCalibration U/Vf0=0.6 vs Qian reference: maxRelDiff={diff:.4e}")
        if diff > 0.02:
            print("  WARNING: >2% difference — review get_bto_cfo calibration")

    csv_path = CASES_DIR / "pilot_cases.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["fg_mode", "vf0", "input_file"])
        w.writerows(manifest)
    print(f"\nManifest: {csv_path} ({len(manifest)} cases)")


if __name__ == "__main__":
    main()
