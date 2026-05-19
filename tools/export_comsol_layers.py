#!/usr/bin/env python3
"""Export layered MATERIAL from a MEET case file to CSV for COMSOL assignment."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

COLS = [
    "layer", "E1", "E2", "v12", "v23", "G12", "G13", "G23",
    "d31", "d32", "angle", "hE", "q31", "q32", "g33", "k33", "r33",
    "A1", "A2", "PyroE", "PyroM", "Cv", "HC", "Density", "zC1", "zC2", "IsSmtLay",
]


def read_layers(path: Path) -> list[list[float]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"MATERIAL START(.*?)MATERIAL END", text, re.DOTALL)
    if not m:
        raise RuntimeError(f"No MATERIAL block in {path}")
    rows = []
    for line in m.group(1).splitlines():
        line = line.strip()
        if line and line[0].isdigit():
            rows.append([float(x) for x in line.split()])
    return rows


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: export_comsol_layers.py <case.txt> [out.csv]")
        sys.exit(1)

    case = Path(sys.argv[1]).resolve()
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else (
        Path(__file__).resolve().parents[1] / "comsol" / "export" / f"{case.stem}_layers.csv"
    )
    out.parent.mkdir(parents=True, exist_ok=True)

    layers = read_layers(case)
    with out.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(COLS)
        for row in layers:
            w.writerow([int(row[0])] + row[1:])

    print(f"Wrote {len(layers)} layers -> {out}")


if __name__ == "__main__":
    main()
