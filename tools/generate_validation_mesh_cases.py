#!/usr/bin/env python3
"""Generate U/Vf0.6 CFFF plate inputs for MATLAB mesh diagnostics.

The bundled 10x10 and 20x20 templates use an older material passport.  This
script preserves their node/element topology but replaces the MATERIAL block
with the same ten U-distribution rows used by the frozen 30x30 baseline.
"""

from __future__ import annotations

import csv
import re
import shutil
from pathlib import Path

from generate_cases import build_layers, patch_material


ROOT = Path(__file__).resolve().parents[1]
INPUT_DIR = ROOT / "matlab" / "meet-elastic-thermal" / "InputFile"
OUTPUT_DIR = ROOT / "cases" / "validation_mesh"


def release_right_edge(path: Path) -> None:
    """Convert the bundled 15x15 CFCF topology to the CFFF boundary.

    The 15x15 mesh exists only as a two-edge-clamped case.  CFFF differs only
    in the mechanical flags on the x=max edge, so preserve the exact topology
    and clear those five flags.  The x=0 edge remains clamped.
    """
    text = path.read_text(encoding="utf-8", errors="strict")
    match = re.search(r"NODE START\n(.*?)\nNODE END", text, re.DOTALL)
    if not match:
        raise RuntimeError(f"NODE block not found in {path}")
    parsed: list[list[str]] = []
    for line in match.group(1).splitlines():
        columns = line.split()
        if columns:
            parsed.append(columns)
    xmax = max(float(columns[1]) for columns in parsed)
    changed = 0
    for columns in parsed:
        if abs(float(columns[1]) - xmax) <= 1e-12:
            columns[4:9] = ["0"] * 5
            changed += 1
    if changed == 0:
        raise RuntimeError(f"No x=max boundary nodes found in {path}")
    node_block = "\n".join("\t".join(columns) for columns in parsed)
    text = text[: match.start(1)] + node_block + text[match.end(1) :]
    path.write_text(text, encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows: list[list[str]] = []
    for mesh in (10, 15, 20, 30):
        boundary = "CFCF" if mesh == 15 else "CFFF"
        source = INPUT_DIR / f"Thermal_{boundary}plate_0.6Vf-{mesh}x{mesh}-10layer.txt"
        target = OUTPUT_DIR / f"Thermal_CFFF_U_Vf0.6-{mesh}x{mesh}-10layer.txt"
        if not source.is_file():
            raise SystemExit(f"Missing mesh template: {source}")
        shutil.copy2(source, target)
        if mesh == 15:
            release_right_edge(target)
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
