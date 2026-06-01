#!/usr/bin/env python3
"""Generate a 10x10 porous CFFF input file for Newmark pilot runs."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from generate_porous_cases import (
    POROSITY_MODE_NAMES,
    build_porous_layers,
    patch_material,
)


WORKBENCH = Path(__file__).resolve().parents[1]
TEMPLATE = (
    WORKBENCH
    / "matlab"
    / "meet-elastic-thermal"
    / "InputFile"
    / "Thermal_CFFFplate_0.6Vf-10x10-10layer.txt"
)
OUT_DIR = WORKBENCH / "cases" / "porous"
POROSITY_NAME_TO_MODE = {v: k for k, v in POROSITY_MODE_NAMES.items()}


def case_name(fg_mode: str, vf0: float, e0: float, porosity_name: str) -> str:
    e0_tag = f"e{int(round(e0 * 100)):02d}"
    return f"Porous_CFFF_{fg_mode}_Vf{vf0:.1f}_{e0_tag}_{porosity_name}-10x10-10layer.txt"


def strip_trailing_whitespace(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    path.write_text("\n".join(line.rstrip() for line in lines) + "\n", encoding="utf-8")


def generate(fg_mode: str, vf0: float, e0: float, porosity_name: str) -> Path:
    if porosity_name not in POROSITY_NAME_TO_MODE:
        valid = ", ".join(POROSITY_NAME_TO_MODE)
        raise SystemExit(f"Unknown porosity mode {porosity_name!r}; valid: {valid}")
    if not TEMPLATE.is_file():
        raise SystemExit(f"Missing template: {TEMPLATE}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / case_name(fg_mode, vf0, e0, porosity_name)
    shutil.copy2(TEMPLATE, out)
    rows = build_porous_layers(
        n_layer=10,
        h=6e-3,
        vf0=vf0,
        fg_mode=fg_mode,
        e0=e0,
        poro_mode=POROSITY_NAME_TO_MODE[porosity_name],
    )
    patch_material(out, rows)
    strip_trailing_whitespace(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("fg_mode", nargs="?", default="U")
    parser.add_argument("vf0", nargs="?", type=float, default=0.5)
    parser.add_argument("e0", nargs="?", type=float, default=0.2)
    parser.add_argument("porosity_name", nargs="?", default="Even")
    args = parser.parse_args()

    out = generate(args.fg_mode, args.vf0, args.e0, args.porosity_name)
    print(f"Generated {out}")


if __name__ == "__main__":
    main()
