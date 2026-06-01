#!/usr/bin/env python3
"""Build report assets for the CFCF static boundary-condition sweep."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "output" / "results_static_cfcf.csv"
CFFF_INPUT = ROOT / "output" / "results_static.csv"
REPORT_DIR = ROOT / "reports" / "2026-06-01-cfcf-static"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README = REPORT_DIR / "README.md"

EXPECTED_ROWS = 30
FG_MODES = ["U", "X"]
LOAD_CASES = ["elastic", "electro", "magneto"]

FONT = Path("C:/Windows/Fonts/msyh.ttc")
FONT_BOLD = Path("C:/Windows/Fonts/msyhbd.ttc")
if not FONT.exists():
    FONT = Path("C:/Windows/Fonts/arial.ttf")
if not FONT_BOLD.exists():
    FONT_BOLD = FONT

COLORS = {
    "ink": "#172033",
    "muted": "#556070",
    "navy": "#1F3A5F",
    "blue": "#2E74B5",
    "green": "#2F7D32",
    "orange": "#B65C00",
    "red": "#9B1C1C",
    "purple": "#6D5DFB",
    "teal": "#087E8B",
    "grid": "#D8DEE8",
    "fill": "#F5F7FA",
}
PALETTE = {
    "elastic": COLORS["blue"],
    "electro": COLORS["green"],
    "magneto": COLORS["orange"],
    "U": COLORS["purple"],
    "X": COLORS["teal"],
}


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT), size=size)


def text_size(draw: ImageDraw.ImageDraw, text: object, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), str(text), font=fnt)
    return box[2] - box[0], box[3] - box[1]


def canvas(title: str, subtitle: str = "", size: tuple[int, int] = (1600, 900)) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", size, "white")
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, size[0], 90], fill=rgb("#F1F5FA"))
    draw.text((42, 18), title, fill=rgb(COLORS["navy"]), font=font(34, True))
    if subtitle:
        draw.text((42, 58), subtitle, fill=rgb(COLORS["muted"]), font=font(18))
    return img, draw


def footer(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
    draw.line([42, size[1] - 44, size[0] - 42, size[1] - 44], fill=rgb("#E1E7EF"), width=2)
    draw.text((42, size[1] - 32), "FG-MEET CFCF static sweep | 2026-06-01", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(path: Path, title: str, headers: list[str], rows: list[list[object]], col_widths: list[int], subtitle: str = "") -> None:
    width = max(1500, sum(col_widths) + 120)
    height = 154 + 58 + max(1, len(rows)) * 56 + 72
    img, draw = canvas(title, subtitle, (width, height))
    x0, y = 42, 122
    total_w = sum(col_widths)
    draw.rectangle([x0, y, x0 + total_w, y + 58], fill=rgb("#E6ECF3"), outline=rgb(COLORS["grid"]))
    x = x0
    for header, cw in zip(headers, col_widths):
        draw.text((x + 12, y + 17), header, fill=rgb(COLORS["navy"]), font=font(18, True))
        draw.line([x, y, x, y + 58 + max(1, len(rows)) * 56], fill=rgb(COLORS["grid"]))
        x += cw
    draw.line([x, y, x, y + 58 + max(1, len(rows)) * 56], fill=rgb(COLORS["grid"]))
    y += 58
    for ri, row in enumerate(rows):
        fill = "#FFFFFF" if ri % 2 == 0 else COLORS["fill"]
        draw.rectangle([x0, y, x0 + total_w, y + 56], fill=rgb(fill), outline=rgb(COLORS["grid"]))
        x = x0
        for value, cw in zip(row, col_widths):
            draw.text((x + 12, y + 16), str(value), fill=rgb(COLORS["ink"]), font=font(16))
            draw.line([x, y, x, y + 56], fill=rgb(COLORS["grid"]))
            x += cw
        draw.line([x, y, x, y + 56], fill=rgb(COLORS["grid"]))
        y += 56
    footer(draw, img.size)
    img.save(path)


def line_chart(path: Path, title: str, subtitle: str, series: dict[str, pd.DataFrame], x_col: str, y_col: str, y_label: str) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 145, 160, 1510, 760
    all_x = [float(v) for df in series.values() for v in df[x_col]]
    all_y = [float(v) for df in series.values() for v in df[y_col]]
    xmin, xmax = min(all_x), max(all_x)
    ymin, ymax = min(all_y), max(all_y)
    if ymin == ymax:
        ymin -= 1
        ymax += 1
    pad = max((ymax - ymin) * 0.08, 1e-9)
    ymin -= pad
    ymax += pad

    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)
    for i in range(6):
        yy = top + i * (bottom - top) / 5
        val = ymax - i * (ymax - ymin) / 5
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((42, yy - 12), f"{val:.3g}", fill=rgb(COLORS["muted"]), font=font(15))
    for i in range(5):
        xx = left + i * (right - left) / 4
        val = xmin + i * (xmax - xmin) / 4
        draw.text((xx - 20, bottom + 20), f"{val:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), "Vf0", fill=rgb(COLORS["muted"]), font=font(17, True))
    draw.text((left - 100, top - 34), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))

    def xy(px: float, py: float) -> tuple[float, float]:
        return (
            left + (px - xmin) / (xmax - xmin) * (right - left),
            bottom - (py - ymin) / (ymax - ymin) * (bottom - top),
        )

    for idx, (name, df) in enumerate(series.items()):
        color = rgb(PALETTE.get(name, list(PALETTE.values())[idx % len(PALETTE)]))
        pts = [xy(float(x), float(y)) for x, y in zip(df[x_col], df[y_col])]
        draw.line(pts, fill=color, width=4)
        for px, py in pts:
            draw.ellipse([px - 5, py - 5, px + 5, py + 5], fill=color)
        lx = left + 18 + idx * 270
        draw.line([lx, 116, lx + 38, 116], fill=color, width=4)
        draw.text((lx + 48, 104), name, fill=rgb(COLORS["ink"]), font=font(16))
    footer(draw, img.size)
    img.save(path)


def load_results() -> pd.DataFrame:
    if not INPUT.exists():
        raise FileNotFoundError(f"Missing {INPUT}")
    df = pd.read_csv(INPUT)
    for col in ["vf0", "w_center_mm", "theta_span_K", "magnetoelectric_efficiency"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    df["w_abs_mm"] = df["w_center_mm"].abs()
    return df


def add_cfff_ratios(df: pd.DataFrame) -> pd.DataFrame:
    if not CFFF_INPUT.exists():
        df["cfff_w_abs_mm"] = pd.NA
        df["w_abs_cfcf_over_cfff"] = pd.NA
        return df
    cfff = pd.read_csv(CFFF_INPUT)
    for col in ["vf0", "w_center_mm", "theta_span_K", "magnetoelectric_efficiency"]:
        cfff[col] = pd.to_numeric(cfff[col], errors="coerce")
    cfff = cfff[cfff["fg_mode"].isin(FG_MODES)].copy()
    cfff["cfff_w_abs_mm"] = cfff["w_center_mm"].abs()
    base = cfff[["fg_mode", "vf0", "load_case", "cfff_w_abs_mm", "theta_span_K", "magnetoelectric_efficiency"]].rename(
        columns={
            "theta_span_K": "cfff_theta_span_K",
            "magnetoelectric_efficiency": "cfff_me_efficiency",
        }
    )
    out = df.merge(base, on=["fg_mode", "vf0", "load_case"], how="left")
    out["w_abs_cfcf_over_cfff"] = out["w_abs_mm"] / out["cfff_w_abs_mm"]
    out["theta_cfcf_over_cfff"] = out["theta_span_K"] / out["cfff_theta_span_K"]
    out["me_cfcf_over_cfff"] = out["magnetoelectric_efficiency"] / out["cfff_me_efficiency"]
    return out


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    df = load_results()
    if len(df) != EXPECTED_ROWS:
        raise RuntimeError(f"Expected {EXPECTED_ROWS} CFCF rows, got {len(df)}")
    bad = df[df["status"].astype(str).str.lower() != "ok"]
    if not bad.empty:
        raise RuntimeError(f"CFCF results contain failed rows: {bad['case_id'].tolist()}")

    enriched = add_cfff_ratios(df)
    copy2(INPUT, DATA_DIR / "results_static_cfcf.csv")
    enriched.to_csv(DATA_DIR / "results_static_cfcf_with_cfff_ratios.csv", index=False)

    summary = (
        enriched.groupby(["fg_mode", "load_case"], as_index=False)
        .agg(
            w_abs_mean_mm=("w_abs_mm", "mean"),
            w_abs_min_mm=("w_abs_mm", "min"),
            w_abs_max_mm=("w_abs_mm", "max"),
            theta_span_mean_K=("theta_span_K", "mean"),
            mean_cfcf_over_cfff=("w_abs_cfcf_over_cfff", "mean"),
        )
        .sort_values(["fg_mode", "load_case"])
    )
    summary.to_csv(DATA_DIR / "cfcf_static_summary_by_group.csv", index=False)

    counts = df.groupby(["fg_mode", "load_case"]).size().reset_index(name="rows")
    table_image(
        FIG_DIR / "01_cfcf_coverage_table.png",
        "CFCF 静力扫描覆盖度",
        ["FG", "载荷", "行数", "Vf0范围"],
        [[r.fg_mode, r.load_case, int(r.rows), "0.1-0.9"] for r in counts.itertuples()],
        [170, 220, 160, 260],
        "2种FG × 5个Vf0 × 3载荷 = 30行",
    )

    for mode in FG_MODES:
        sub = enriched[enriched["fg_mode"] == mode].sort_values("vf0")
        series = {lc: sub[sub["load_case"] == lc] for lc in LOAD_CASES}
        line_chart(
            FIG_DIR / f"02_{mode}_cfcf_w_abs_vs_vf0.png",
            f"{mode}分布 CFCF 中心挠度",
            "30x30, 10层, 三载荷静力响应",
            series,
            "vf0",
            "w_abs_mm",
            "|w_center| (mm)",
        )
        line_chart(
            FIG_DIR / f"03_{mode}_cfcf_theta_span_vs_vf0.png",
            f"{mode}分布 CFCF 层温差",
            "theta_span 随体积分数变化",
            series,
            "vf0",
            "theta_span_K",
            "theta span (K)",
        )
        ratio_series = {
            lc: sub[(sub["load_case"] == lc) & sub["w_abs_cfcf_over_cfff"].notna()]
            for lc in LOAD_CASES
        }
        line_chart(
            FIG_DIR / f"04_{mode}_cfcf_over_cfff_w_ratio.png",
            f"{mode}分布 CFCF/CFFF 挠度比",
            "小于1表示CFCF边界显著抑制中心挠度",
            ratio_series,
            "vf0",
            "w_abs_cfcf_over_cfff",
            "|w| ratio",
        )

    magneto = enriched[enriched["load_case"] == "magneto"].sort_values("vf0")
    line_chart(
        FIG_DIR / "05_cfcf_me_efficiency_vs_vf0.png",
        "CFCF 磁电转换效率",
        "magneto 工况，electric span / (2H)",
        {mode: magneto[magneto["fg_mode"] == mode] for mode in FG_MODES},
        "vf0",
        "magnetoelectric_efficiency",
        "ME efficiency",
    )

    ratio_rows = []
    elastic = enriched[enriched["load_case"] == "elastic"].copy()
    for row in elastic.sort_values("w_abs_cfcf_over_cfff").itertuples():
        ratio_rows.append([
            row.fg_mode,
            f"{row.vf0:.1f}",
            f"{row.w_abs_mm:.4f}",
            f"{row.cfff_w_abs_mm:.4f}",
            f"{row.w_abs_cfcf_over_cfff:.3f}",
        ])
    table_image(
        FIG_DIR / "06_cfcf_boundary_reduction_table.png",
        "CFCF 相对 CFFF 的机械挠度抑制",
        ["FG", "Vf0", "CFCF |w|", "CFFF |w|", "比值"],
        ratio_rows,
        [150, 150, 220, 220, 160],
        "elastic Case A 中心点对比",
    )

    best_reduction = elastic.loc[elastic["w_abs_cfcf_over_cfff"].idxmin()]
    strongest_cfcf = elastic.loc[elastic["w_abs_mm"].idxmax()]
    max_me = magneto.loc[magneto["magnetoelectric_efficiency"].idxmax()]

    README.write_text(
        f"""# CFCF 静力边界扩展（2026-06-01）

本报告整理 `run_batch_static_cfcf.m` 的 30x30 静力扫描结果。参数空间为 U/X 两种 FG 分布、Vf0=0.1/0.3/0.5/0.7/0.9、elastic/electro/magneto 三载荷，共 {len(df)} 行，全部为 ok。

## 关键结论

- CFCF 边界显著抑制中心挠度；elastic 工况中最强抑制为 {best_reduction.fg_mode}/Vf0={best_reduction.vf0:.1f}，CFCF/CFFF 挠度比 {best_reduction.w_abs_cfcf_over_cfff:.3f}。
- CFCF 下最大的 elastic 中心挠度为 {strongest_cfcf.fg_mode}/Vf0={strongest_cfcf.vf0:.1f}，|w_center|={strongest_cfcf.w_abs_mm:.4f} mm。
- magneto 工况中最高磁电效率为 {max_me.fg_mode}/Vf0={max_me.vf0:.1f}，ME efficiency={max_me.magnetoelectric_efficiency:.4f}。

## 文件

- `data/results_static_cfcf.csv`: 原始 CFCF 结果。
- `data/results_static_cfcf_with_cfff_ratios.csv`: 合并 CFFF 基线后的边界比值。
- `data/cfcf_static_summary_by_group.csv`: 按 FG/载荷聚合。
- `figures/`: 覆盖度、中心挠度、层温差、CFCF/CFFF 比值和磁电效率图。
""",
        encoding="utf-8",
    )

    print(f"Wrote {REPORT_DIR}")


if __name__ == "__main__":
    build()
