from __future__ import annotations

import csv
import importlib.util
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
WORK_DIR = Path(__file__).resolve().parent
MAT_READER = ROOT / "outputs" / "manual-20260611-fgmeet" / "qian-force-displacement" / "extract_mat_fig_curves.py"
OUT_CSV = WORK_DIR / "predecessor_mat_string_inventory.csv"


def load_mat_reader():
    spec = importlib.util.spec_from_file_location("extract_mat_fig_curves", MAT_READER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load MAT reader from {MAT_READER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def walk_strings(obj: Any, path: str = ""):
    if isinstance(obj, str):
        value = obj.strip()
        if value:
            yield path, value
        return
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key.startswith("__"):
                continue
            next_path = f"{path}.{key}" if path else key
            yield from walk_strings(value, next_path)
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            yield from walk_strings(value, f"{path}[{idx}]")


def main() -> None:
    mat_reader = load_mat_reader()
    roots = [
        ROOT / "reference" / "predecessor-code" / "qian-shenyun",
        ROOT / "reference" / "predecessor-code" / "zhao-yafei",
    ]
    files: list[Path] = []
    for root in roots:
        for pattern in ("*.fig", "*.mat"):
            files.extend(root.rglob(pattern))
    files = sorted(files)

    rows: list[dict[str, str]] = []
    for file in files:
        try:
            mat = mat_reader.read_mat_file(file)
        except Exception as exc:  # noqa: BLE001 - inventory should continue
            rows.append(
                {
                    "source": str(file.relative_to(ROOT)),
                    "path": "",
                    "text": "",
                    "note": f"parse_error: {exc}",
                }
            )
            continue
        seen: set[tuple[str, str]] = set()
        for path, text in walk_strings(mat):
            if len(text) > 300:
                continue
            key = (path, text)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "source": str(file.relative_to(ROOT)),
                    "path": path,
                    "text": text,
                    "note": "",
                }
            )

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=["source", "path", "text", "note"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"scanned_files={len(files)}")
    print(f"string_rows={len(rows)}")
    print(f"wrote {OUT_CSV}")


if __name__ == "__main__":
    main()
