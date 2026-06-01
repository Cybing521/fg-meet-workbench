#!/usr/bin/env python3
"""Build report assets for the porous 10x10 Newmark representative run."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TAG = "dynamic_porous_U_Vf50_e20_Even_10x10"
SUMMARY_CSV = ROOT / "output" / f"{TAG}_summary.csv"
TIMESERIES_CSV = ROOT / "output" / f"{TAG}_timeseries.csv"
REPORT_DIR = ROOT / "reports" / "2026-06-01-porous-dynamic"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README = REPORT_DIR / "README.md"

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
    "grid": "#D8DEE8",
    "fill": "#F5F7FA",
}


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT), size=size)


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
    draw.text((42, size[1] - 32), "FG-MEET porous Newmark pilot | 2026-06-01", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(path: Path, title: str, headers: list[str], rows: list[list[object]], col_widths: list[int], subtitle: str = "") -> None:
    width = max(1500, sum(col_widths) + 120)
    height = 154 + 58 + max(1, len(rows)) * 58 + 72
    img, draw = canvas(title, subtitle, (width, height))
    x0, y = 42, 122
    total_w = sum(col_widths)
    draw.rectangle([x0, y, x0 + total_w, y + 58], fill=rgb("#E6ECF3"), outline=rgb(COLORS["grid"]))
    x = x0
    for header, cw in zip(headers, col_widths):
        draw.text((x + 12, y + 17), header, fill=rgb(COLORS["navy"]), font=font(18, True))
        draw.line([x, y, x, y + 58 + len(rows) * 58], fill=rgb(COLORS["grid"]))
        x += cw
    draw.line([x, y, x, y + 58 + len(rows) * 58], fill=rgb(COLORS["grid"]))
    y += 58
    for ri, row in enumerate(rows):
        fill = "#FFFFFF" if ri % 2 == 0 else COLORS["fill"]
        draw.rectangle([x0, y, x0 + total_w, y + 58], fill=rgb(fill), outline=rgb(COLORS["grid"]))
        x = x0
        for value, cw in zip(row, col_widths):
            draw.text((x + 12, y + 17), str(value), fill=rgb(COLORS["ink"]), font=font(16))
            draw.line([x, y, x, y + 58], fill=rgb(COLORS["grid"]))
            x += cw
        draw.line([x, y, x, y + 58], fill=rgb(COLORS["grid"]))
        y += 58
    footer(draw, img.size)
    img.save(path)


def line_chart(path: Path, title: str, subtitle: str, df: pd.DataFrame, y_col: str, y_label: str, color: str) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 145, 160, 1510, 760
    x = pd.to_numeric(df["time_s"], errors="coerce") * 1000.0
    y = pd.to_numeric(df[y_col], errors="coerce")
    xmin, xmax = float(x.min()), float(x.max())
    ymin, ymax = float(y.min()), float(y.max())
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
    for i in range(6):
        xx = left + i * (right - left) / 5
        val = xmin + i * (xmax - xmin) / 5
        draw.text((xx - 24, bottom + 20), f"{val:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), "time (ms)", fill=rgb(COLORS["muted"]), font=font(17, True))
    draw.text((left - 100, top - 34), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))

    def xy(px: float, py: float) -> tuple[float, float]:
        return (
            left + (px - xmin) / (xmax - xmin) * (right - left),
            bottom - (py - ymin) / (ymax - ymin) * (bottom - top),
        )

    pts = [xy(float(px), float(py)) for px, py in zip(x, y)]
    draw.line(pts, fill=rgb(color), width=4)
    footer(draw, img.size)
    img.save(path)


def build() -> None:
    if not SUMMARY_CSV.exists() or not TIMESERIES_CSV.exists():
        raise FileNotFoundError(f"Missing porous dynamic outputs for {TAG}")

    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary = pd.read_csv(SUMMARY_CSV)
    ts = pd.read_csv(TIMESERIES_CSV)
    row = summary.iloc[0]

    copy2(SUMMARY_CSV, DATA_DIR / SUMMARY_CSV.name)
    copy2(TIMESERIES_CSV, DATA_DIR / TIMESERIES_CSV.name)

    table_rows = [
        ["模型", "U / Vf0=0.5 / e0=0.2 / Even / 10x10"],
        ["时间步", f"{float(row.dt_s):.1e} s × {int(row.steps)} steps"],
        ["静力中心挠度", f"{float(row.static_center_mm):.4f} mm"],
        ["峰值中心挠度", f"{float(row.peak_center_mm):.4f} mm @ {float(row.peak_time_s) * 1000:.2f} ms"],
        ["超调比", f"{float(row.overshoot_ratio):.3f}"],
        ["最大层温差", f"{float(row.theta_span_max_K):.4f} K"],
        ["频率状态", str(row.frequency_status)],
    ]
    if "freq_01_Hz" in summary.columns and pd.notna(row.get("freq_01_Hz")):
        table_rows.append(["一阶频率", f"{float(row.freq_01_Hz):.2f} Hz"])

    table_image(
        FIG_DIR / "01_porous_dynamic_summary_table.png",
        "含孔隙 10x10 Newmark 代表工况",
        ["指标", "数值"],
        table_rows,
        [360, 900],
        "Phase 6.4: U / Vf0=0.5 / e0=0.2 / Even",
    )
    line_chart(
        FIG_DIR / "02_porous_dynamic_center_timeseries.png",
        "中心挠度时程",
        "Case A step load, full Newmark pilot",
        ts,
        "w_center_mm",
        "w_center (mm)",
        COLORS["blue"],
    )
    line_chart(
        FIG_DIR / "03_porous_dynamic_theta_span_timeseries.png",
        "层温差时程",
        "由 Newmark 响应回代热自由度得到",
        ts,
        "theta_span_K",
        "theta span (K)",
        COLORS["orange"],
    )

    README.write_text(
        f"""# 含孔隙动力代表算例（2026-06-01）

本报告整理 `run_dynamic_porous_representative.m` 的 10x10 完整 Newmark pilot。工况为 U / Vf0=0.5 / e0=0.2 / Even / CFFF / Case A step load，作为 30x30 模态降阶前的流程验证与趋势参考。

## 关键结果

- 静力中心挠度：{float(row.static_center_mm):.4f} mm。
- 动态峰值中心挠度：{float(row.peak_center_mm):.4f} mm，峰值时刻 {float(row.peak_time_s) * 1000:.2f} ms。
- 超调比：{float(row.overshoot_ratio):.3f}。
- 最大层温差：{float(row.theta_span_max_K):.4f} K。
- 频率求解状态：{row.frequency_status}。

## 文件

- `data/{SUMMARY_CSV.name}`: 动力摘要。
- `data/{TIMESERIES_CSV.name}`: 中心挠度与层温差时程。
- `figures/`: 摘要表、中心挠度时程、层温差时程。
""",
        encoding="utf-8",
    )
    print(f"Wrote {REPORT_DIR}")


if __name__ == "__main__":
    build()
