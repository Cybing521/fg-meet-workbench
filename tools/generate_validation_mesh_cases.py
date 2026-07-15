#!/usr/bin/env python3
"""Generate U/Vf0.6 CFFF plate inputs for MATLAB mesh diagnostics.

The bundled 10x10 and 20x20 templates use an older material passport.  This
script preserves their node/element topology but replaces the MATERIAL block
with the same ten U-distribution rows used by the frozen 30x30 baseline.
"""

from __future__ import annotations

import csv
import shutil
from pathlib import Path

from generate_cases import build_layers, patch_material


ROOT = Path(__file__).resolve().parents[1]
INPUT_DIR = ROOT / "matlab" / "meet-elastic-thermal" / "InputFile"
OUTPUT_DIR = ROOT / "cases" / "validation_mesh"


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows: list[list[str]] = []
    for mesh in (10, 20):
        source = INPUT_DIR / f"Thermal_CFFFplate_0.6Vf-{mesh}x{mesh}-10layer.txt"
        target = OUTPUT_DIR / f"Thermal_CFFF_U_Vf0.6-{mesh}x{mesh}-10layer.txt"
        if not source.is_file():
            raise SystemExit(f"Missing mesh template: {source}")
        shutil.copy2(source, target)
        patch_material(
            target,
            build_layers(10, 6e-3, 0.6, "U", 2),
            f"MATLAB mesh diagnostic U Vf0=0.6 {mesh}x{mesh}",
        )
        rows.append([str(mesh), str(target.relative_to(ROOT)).replace("\\", "/")])
        print(f"Generated {target}")

    manifest = OUTPUT_DIR / "manifest.csv"
    with manifest.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["mesh_divisions", "input_file"])
        writer.writerows(rows)
    print(f"Manifest: {manifest}")


if __name__ == "__main__":
    main()
