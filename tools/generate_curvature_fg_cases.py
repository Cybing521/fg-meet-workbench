"""Generate matched CFFF cylindrical-shell U/X cases from audited templates."""

from __future__ import annotations

import csv
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "cases" / "curvature_fg"


def block(text: str, start: str, end: str) -> str:
    i0 = text.index(start) + len(start)
    i1 = text.index(end, i0)
    return text[i0:i1]


def replace_block(text: str, start: str, end: str, replacement: str) -> str:
    i0 = text.index(start) + len(start)
    i1 = text.index(end, i0)
    return text[:i0] + replacement + text[i1:]


def material_hash(text: str) -> str:
    payload = block(text, "MATERIAL START", "MATERIAL END").encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def material_numeric_hash(text: str) -> str:
    """Hash whitespace-normalized material tokens for cross-mesh audits."""
    payload = "|".join(block(text, "MATERIAL START", "MATERIAL END").split())
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def node_radius(text: str) -> float:
    radii: list[float] = []
    for raw in block(text, "NODE START", "NODE END").splitlines():
        cols = re.split(r"\s+", raw.strip())
        if len(cols) >= 4 and cols[0].isdigit():
            radii.append(float(cols[3]))
    if not radii:
        raise ValueError("case contains no node radii")
    if max(radii) - min(radii) > 1e-12:
        raise ValueError("case node radius is not constant")
    return sum(radii) / len(radii)


def normalize_input_comment(text: str, radius: float, mesh: int) -> str:
    """Keep the human-readable header consistent with the numeric node block."""
    return re.sub(
        r"Input file\s+%[^\r\n]*",
        f"Input file  %300mm*300mm*6mm CFFF cylinder, radius={radius:g}m, mesh={mesh}x{mesh}, generated matched case",
        text,
        count=1,
    )


def cylinder_from_flat(flat_text: str, radius: float, mesh: int) -> str:
    text = flat_text.replace("\nPLATE\nLRT5\n", "\nCYLINDER\nLRT5\n", 1)
    node_text = block(text, "NODE START", "NODE END")
    new_lines: list[str] = []
    for raw in node_text.splitlines():
        if not raw.strip():
            new_lines.append(raw)
            continue
        cols = re.split(r"\s+", raw.strip())
        if len(cols) < 12 or not cols[0].isdigit():
            new_lines.append(raw)
            continue
        x = float(cols[1])
        arc = float(cols[2])
        cols[1] = f"{x:.12g}"
        cols[2] = f"{arc / radius:.12g}"
        cols[3] = f"{radius:.12g}"
        fixed = "1" if abs(arc) < 1e-14 else "0"
        cols[4:9] = [fixed] * 5
        new_lines.append("\t".join(cols))
    replacement = "\n" + "\n".join(new_lines) + "\n"
    text = replace_block(text, "NODE START", "NODE END", replacement)
    text = normalize_input_comment(text, radius, mesh)
    return text


def write_case(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    flat_u_10 = (ROOT / "cases" / "validation_mesh" / "Thermal_CFFF_U_Vf0.6-10x10-10layer.txt").read_text(encoding="utf-8")
    flat_x_10 = (ROOT / "cases" / "dynamic_10x10" / "Thermal_CFFF_X_Vf0.6-10x10-10layer.txt").read_text(encoding="utf-8")
    flat_u_30 = (ROOT / "cases" / "Thermal_CFFF_U_Vf0.6-30x30-10layer.txt").read_text(encoding="utf-8")
    flat_x_30 = (ROOT / "cases" / "Thermal_CFFF_X_Vf0.6-30x30-10layer.txt").read_text(encoding="utf-8")
    u_material = block(flat_u_30, "MATERIAL START", "MATERIAL END")
    x_material = block(flat_x_30, "MATERIAL START", "MATERIAL END")

    rows: list[dict[str, object]] = []
    for mode, flat in (("U", flat_u_10), ("X", flat_x_10)):
        canonical_material = u_material if mode == "U" else x_material
        flat = replace_block(flat, "MATERIAL START", "MATERIAL END", canonical_material)
        for radius in (1.0, 0.4, 0.3, 0.2):
            text = cylinder_from_flat(flat, radius, 10)
            name = f"Thermal_CFFF_{mode}_Vf0.6_R{radius:g}m-10x10-10layer.txt"
            path = OUT / "10x10" / name
            write_case(path, text)
            rows.append({
                "mesh": 10, "mode": mode, "geometry": "cylinder", "radius_m": radius,
                "case_file": str(path), "material_sha256": material_hash(text),
                "material_numeric_sha256": material_numeric_hash(text),
                "actual_node_radius_m": node_radius(text),
                "geometry_source": "flat_10x10_coordinate_transform",
            })

    elastic_dir = ROOT / "matlab" / "meet-elastic-thermal" / "InputFile"
    flat_u_20 = (ROOT / "cases" / "validation_mesh" / "Thermal_CFFF_U_Vf0.6-20x20-10layer.txt").read_text(encoding="utf-8")
    for mode in ("U", "X"):
        canonical_material = u_material if mode == "U" else x_material
        flat20 = replace_block(
            flat_u_20, "MATERIAL START", "MATERIAL END", canonical_material
        )
        for radius in (1.0, 0.4, 0.3, 0.2):
            text = cylinder_from_flat(flat20, radius, 20)
            name = f"Thermal_CFFF_{mode}_Vf0.6_R{radius:g}m-20x20-10layer.txt"
            path = OUT / "20x20" / name
            write_case(path, text)
            rows.append({
                "mesh": 20, "mode": mode, "geometry": "cylinder", "radius_m": radius,
                "case_file": str(path), "material_sha256": material_hash(text),
                "material_numeric_sha256": material_numeric_hash(text),
                "actual_node_radius_m": node_radius(text),
                "geometry_source": "flat_20x20_coordinate_transform",
            })

    source_names = {
        1.0: "Thermal_CFFFcylinder_0.6Vf_R1m-30x30-10layer.txt",
        0.4: "Thermal_CFFFcylinder_0.6Vf_R0.4m-30x30-10layer.txt",
        0.3: "Thermal_CFFFcylinder_0.6Vf_R0.3m-30x30-10layer.txt",
        0.2: "Thermal_CFFFcylinder_0.6Vf_R0.2m-30x30-10layer.txt",
    }
    for radius, source_name in source_names.items():
        source_text = (elastic_dir / source_name).read_text(encoding="utf-8")
        for mode in ("U", "X"):
            canonical_material = u_material if mode == "U" else x_material
            text = replace_block(
                source_text, "MATERIAL START", "MATERIAL END", canonical_material
            )
            text = normalize_input_comment(text, radius, 30)
            name = f"Thermal_CFFF_{mode}_Vf0.6_R{radius:g}m-30x30-10layer.txt"
            path = OUT / "30x30" / name
            write_case(path, text)
            rows.append({
                "mesh": 30, "mode": mode, "geometry": "cylinder", "radius_m": radius,
                "case_file": str(path), "material_sha256": material_hash(text),
                "material_numeric_sha256": material_numeric_hash(text),
                "actual_node_radius_m": node_radius(text),
                "geometry_source": source_name,
            })

    with (OUT / "curvature_case_manifest.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"generated={len(rows)} manifest={OUT / 'curvature_case_manifest.csv'}")


if __name__ == "__main__":
    main()
