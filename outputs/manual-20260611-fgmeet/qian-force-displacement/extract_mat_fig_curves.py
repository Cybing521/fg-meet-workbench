from __future__ import annotations

import csv
import math
import struct
import sys
import zlib
from pathlib import Path
from typing import Any


MI_INT8 = 1
MI_UINT8 = 2
MI_INT16 = 3
MI_UINT16 = 4
MI_INT32 = 5
MI_UINT32 = 6
MI_SINGLE = 7
MI_DOUBLE = 9
MI_INT64 = 12
MI_UINT64 = 13
MI_MATRIX = 14
MI_COMPRESSED = 15
MI_UTF8 = 16
MI_UTF16 = 17
MI_UTF32 = 18

KNOWN_DTYPES = {
    MI_INT8,
    MI_UINT8,
    MI_INT16,
    MI_UINT16,
    MI_INT32,
    MI_UINT32,
    MI_SINGLE,
    MI_DOUBLE,
    MI_INT64,
    MI_UINT64,
    MI_MATRIX,
    MI_COMPRESSED,
    MI_UTF8,
    MI_UTF16,
    MI_UTF32,
}

MX_CELL = 1
MX_STRUCT = 2
MX_OBJECT = 3
MX_CHAR = 4
MX_DOUBLE = 6
MX_SINGLE = 7
MX_INT8 = 8
MX_UINT8 = 9
MX_INT16 = 10
MX_UINT16 = 11
MX_INT32 = 12
MX_UINT32 = 13
MX_INT64 = 14
MX_UINT64 = 15


NUMERIC_DTYPES = {
    MI_INT8: ("b", 1),
    MI_UINT8: ("B", 1),
    MI_INT16: ("h", 2),
    MI_UINT16: ("H", 2),
    MI_INT32: ("i", 4),
    MI_UINT32: ("I", 4),
    MI_SINGLE: ("f", 4),
    MI_DOUBLE: ("d", 8),
    MI_INT64: ("q", 8),
    MI_UINT64: ("Q", 8),
}


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def remaining(self) -> int:
        return len(self.data) - self.pos

    def read(self, n: int) -> bytes:
        if self.pos + n > len(self.data):
            raise EOFError("unexpected end of MAT stream")
        out = self.data[self.pos : self.pos + n]
        self.pos += n
        return out

    def skip_padding(self, n: int) -> None:
        pad = (8 - (n % 8)) % 8
        if pad:
            self.read(pad)

    def read_element(self) -> tuple[int, bytes]:
        raw = self.read(8)
        first, second = struct.unpack("<II", raw)
        small_type = first & 0xFFFF
        small_nbytes = first >> 16
        if small_nbytes and small_nbytes <= 4 and small_type in KNOWN_DTYPES:
            return small_type, raw[4 : 4 + small_nbytes]
        nbytes = second
        payload = self.read(nbytes)
        self.skip_padding(nbytes)
        return first, payload

    def peek_element_type(self) -> tuple[int, int, int]:
        if self.remaining() < 8:
            return 0, 0, 0
        first, second = struct.unpack("<II", self.data[self.pos : self.pos + 8])
        small_type = first & 0xFFFF
        small_nbytes = first >> 16
        if small_nbytes and small_nbytes <= 4 and small_type in KNOWN_DTYPES:
            return small_type, small_nbytes, 4
        return first, second, 8


def prod(values: list[int]) -> int:
    out = 1
    for value in values:
        out *= value
    return out


def read_numeric_payload(dtype: int, payload: bytes) -> list[float | int]:
    if dtype not in NUMERIC_DTYPES:
        return []
    fmt, size = NUMERIC_DTYPES[dtype]
    count = len(payload) // size
    if count <= 0:
        return []
    return list(struct.unpack("<" + fmt * count, payload[: count * size]))


def read_text(dtype: int, payload: bytes) -> str:
    if dtype in (MI_INT8, MI_UINT8, MI_UTF8):
        return payload.rstrip(b"\x00").decode("utf-8", errors="ignore")
    if dtype in (MI_INT16, MI_UINT16, MI_UTF16):
        return payload.rstrip(b"\x00").decode("utf-16le", errors="ignore")
    if dtype == MI_UTF32:
        return payload.rstrip(b"\x00").decode("utf-32le", errors="ignore")
    return ""


def parse_elements(data: bytes) -> dict[str, Any]:
    reader = Reader(data)
    values: dict[str, Any] = {}
    while reader.remaining() >= 8:
        peek_type, peek_nbytes, _ = reader.peek_element_type()
        if peek_type not in KNOWN_DTYPES or peek_nbytes > reader.remaining():
            break
        dtype, payload = reader.read_element()
        if dtype == MI_COMPRESSED:
            values.update(parse_elements(zlib.decompress(payload)))
        elif dtype == MI_MATRIX:
            name, value = parse_matrix(payload)
            values[name or f"unnamed_{len(values)}"] = value
        else:
            # Top-level non-matrix elements are not useful for figure extraction.
            pass
    return values


def parse_matrix(payload: bytes) -> tuple[str, Any]:
    if len(payload) < 8:
        return "", []
    reader = Reader(payload)

    flags_type, flags_payload = reader.read_element()
    flags = read_numeric_payload(flags_type, flags_payload)
    mx_class = int(flags[0]) & 0xFF if flags else 0

    dims_type, dims_payload = reader.read_element()
    dims = [int(x) for x in read_numeric_payload(dims_type, dims_payload)]
    if not dims:
        dims = [1, 1]
    nitems = prod(dims)

    name_type, name_payload = reader.read_element()
    name = read_text(name_type, name_payload)

    if mx_class in (MX_STRUCT, MX_OBJECT):
        # MATLAB objects in old HG figures are structurally encoded enough for
        # our purpose: fields, children and properties carry the plotted arrays.
        if reader.remaining() < 8:
            return name, {"__class__": mx_class, "__dims__": dims}
        fl_type, fl_payload = reader.read_element()
        field_name_length = int(read_numeric_payload(fl_type, fl_payload)[0])
        fn_type, fn_payload = reader.read_element()
        raw_names = fn_payload
        field_names = []
        if field_name_length > 0:
            for offset in range(0, len(raw_names), field_name_length):
                field = raw_names[offset : offset + field_name_length].split(b"\x00", 1)[0]
                if field:
                    field_names.append(field.decode("utf-8", errors="ignore"))
        entries: list[dict[str, Any]] = []
        for _ in range(max(nitems, 1)):
            entry: dict[str, Any] = {"__class__": mx_class, "__dims__": dims}
            for field in field_names:
                if reader.remaining() < 8:
                    entry[field] = None
                    continue
                value_type, value_payload = reader.read_element()
                if value_type == MI_COMPRESSED:
                    sub_values = parse_elements(zlib.decompress(value_payload))
                    entry[field] = sub_values
                elif value_type == MI_MATRIX:
                    sub_name, sub_value = parse_matrix(value_payload)
                    entry[field] = sub_value
                    if sub_name:
                        entry[f"__name_for_{field}"] = sub_name
                else:
                    entry[field] = read_numeric_payload(value_type, value_payload)
            entries.append(entry)
        return name, entries[0] if len(entries) == 1 else entries

    if mx_class == MX_CELL:
        cells = []
        for _ in range(max(nitems, 1)):
            if reader.remaining() < 8:
                cells.append(None)
                continue
            cell_type, cell_payload = reader.read_element()
            if cell_type == MI_COMPRESSED:
                cells.append(parse_elements(zlib.decompress(cell_payload)))
            elif cell_type == MI_MATRIX:
                _, cell_value = parse_matrix(cell_payload)
                cells.append(cell_value)
            else:
                cells.append(read_numeric_payload(cell_type, cell_payload))
        return name, cells

    if mx_class == MX_CHAR:
        if reader.remaining() < 8:
            return name, ""
        dtype, data = reader.read_element()
        text = read_text(dtype, data)
        return name, text

    if reader.remaining() < 8:
        return name, []
    dtype, data = reader.read_element()
    values = read_numeric_payload(dtype, data)
    if len(values) == 1:
        return name, values[0]
    return name, {"__class__": mx_class, "__dims__": dims, "data": values}


def summarize_numeric(value: Any) -> dict[str, Any] | None:
    if isinstance(value, dict) and "data" in value:
        data = value["data"]
    elif isinstance(value, list):
        data = value
    else:
        return None
    numeric = [float(x) for x in data if isinstance(x, (int, float)) and math.isfinite(float(x))]
    if not numeric:
        return None
    return {
        "n": len(numeric),
        "min": min(numeric),
        "max": max(numeric),
        "first": numeric[0],
        "mid": numeric[len(numeric) // 2],
        "last": numeric[-1],
        "data": numeric,
    }


def walk(obj: Any, path: str = ""):
    if isinstance(obj, dict):
        yield path, obj
        for key, value in obj.items():
            if key.startswith("__"):
                continue
            yield from walk(value, f"{path}.{key}" if path else key)
    elif isinstance(obj, list):
        for idx, value in enumerate(obj):
            yield from walk(value, f"{path}[{idx}]")


def extract_curves(mat: dict[str, Any], source_name: str) -> list[dict[str, Any]]:
    curves = []
    for path, obj in walk(mat):
        if not isinstance(obj, dict):
            continue
        x_summary = summarize_numeric(obj.get("XData"))
        y_summary = summarize_numeric(obj.get("YData"))
        if x_summary and y_summary:
            label = ""
            for key in ("DisplayName", "Tag", "Type"):
                raw = obj.get(key)
                if isinstance(raw, str) and raw:
                    label = raw
                    break
            n = min(x_summary["n"], y_summary["n"])
            curves.append(
                {
                    "source": source_name,
                    "path": path,
                    "label": label,
                    "n": n,
                    "x_min": x_summary["min"],
                    "x_max": x_summary["max"],
                    "x_first": x_summary["first"],
                    "x_mid": x_summary["mid"],
                    "x_last": x_summary["last"],
                    "y_min": y_summary["min"],
                    "y_max": y_summary["max"],
                    "y_first": y_summary["first"],
                    "y_mid": y_summary["mid"],
                    "y_last": y_summary["last"],
                    "x_data": x_summary["data"][:n],
                    "y_data": y_summary["data"][:n],
                }
            )
    return curves


def read_mat_file(path: Path) -> dict[str, Any]:
    raw = path.read_bytes()
    if len(raw) > 128 and raw[126:128] in (b"IM", b"MI"):
        return parse_elements(raw[128:])
    return parse_elements(raw)


def write_curve_csv(curves: list[dict[str, Any]], out_dir: Path) -> None:
    summary_path = out_dir / "qian_fig_curve_summary.csv"
    with summary_path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "source",
                "path",
                "label",
                "n",
                "x_min",
                "x_max",
                "x_first",
                "x_mid",
                "x_last",
                "y_min",
                "y_max",
                "y_first",
                "y_mid",
                "y_last",
            ],
        )
        writer.writeheader()
        for curve in curves:
            writer.writerow({key: curve.get(key, "") for key in writer.fieldnames})

    for idx, curve in enumerate(curves, start=1):
        safe_name = f"curve_{idx:02d}.csv"
        with (out_dir / safe_name).open("w", newline="", encoding="utf-8-sig") as handle:
            writer = csv.writer(handle)
            writer.writerow(["x", "y"])
            for x, y in zip(curve["x_data"], curve["y_data"]):
                writer.writerow([x, y])


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: extract_mat_fig_curves.py OUT_DIR FILE [FILE ...]", file=sys.stderr)
        return 2
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)
    curves: list[dict[str, Any]] = []
    for raw_path in sys.argv[2:]:
        path = Path(raw_path)
        try:
            mat = read_mat_file(path)
            found = extract_curves(mat, path.name)
            print(f"{path.name}: {len(found)} curves")
            curves.extend(found)
        except Exception as exc:  # noqa: BLE001 - diagnostics for archival files
            print(f"{path}: ERROR {exc}", file=sys.stderr)
    write_curve_csv(curves, out_dir)
    print(f"wrote {len(curves)} curves to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
