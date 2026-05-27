#!/usr/bin/env python3
"""Build report assets for the 10x10 Newmark FG-mode dynamic sweep."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "2026-05-27-dynamic-fg-sweep"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README_PATH = REPORT_DIR / "README.md"

MODES = ["U", "V", "X", "O", "P"]
TAG_PREFIX = "dynamic_10x10"
TAG_SUFFIX = "Vf06_elastic_fgsweep"

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
PALETTE = [COLORS["blue"], COLORS["green"], COLORS["orange"], COLORS["purple"], COLORS["teal"]]


def tag(mode: str) -> str:
    return f"{TAG_PREFIX}_{mode}_{TAG_SUFFIX}"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT), size=size)


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def wrap(draw: ImageDraw.ImageDraw, text: object, fnt: ImageFont.FreeTypeFont, width: int) -> list[str]:
    s = str(text)
    if not s:
        return [""]
    lines: list[str] = []
    current = ""
    for ch in s:
        candidate = current + ch
        if text_size(draw, candidate, fnt)[0] <= width or not current:
            current = candidate
        else:
            lines.append(current)
            current = ch
    if current:
        lines.append(current)
    return lines


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
    draw.text((42, size[1] - 32), "FG-MEET 10x10 Newmark FG sweep | 2026-05-27", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(path: Path, title: str, headers: list[str], rows: list[list[object]], col_widths: list[int], subtitle: str = "") -> None:
    width = max(1500, sum(col_widths) + 120)
    tmp = Image.new("RGB", (width, 2000), "white")
    dtmp = ImageDraw.Draw(tmp)
    f_head = font(19, True)
    f_body = font(17)
    row_heights = []
    for row in rows:
        max_lines = 1
        for value, cw in zip(row, col_widths):
            max_lines = max(max_lines, len(wrap(dtmp, value, f_body, cw - 24)))
        row_heights.append(max(54, 24 + max_lines * 28))
    height = 154 + 58 + sum(row_heights) + 70
    img, draw = canvas(title, subtitle, (width, height))
    x0, y = 42, 122
    draw.rectangle([x0, y, x0 + sum(col_widths), y + 58], fill=rgb("#E6ECF3"), outline=rgb(COLORS["grid"]))
    x = x0
    for header, cw in zip(headers, col_widths):
        draw.text((x + 12, y + 17), header, fill=rgb(COLORS["navy"]), font=f_head)
        draw.line([x, y, x, y + 58 + sum(row_heights)], fill=rgb(COLORS["grid"]))
        x += cw
    draw.line([x, y, x, y + 58 + sum(row_heights)], fill=rgb(COLORS["grid"]))
    y += 58
    for ri, row in enumerate(rows):
        fill = "#FFFFFF" if ri % 2 == 0 else COLORS["fill"]
        draw.rectangle([x0, y, x0 + sum(col_widths), y + row_heights[ri]], fill=rgb(fill), outline=rgb(COLORS["grid"]))
        x = x0
        for value, cw in zip(row, col_widths):
            yy = y + 14
            for line in wrap(draw, value, f_body, cw - 24):
                draw.text((x + 12, yy), line, fill=rgb(COLORS["ink"]), font=f_body)
                yy += 28
            draw.line([x, y, x, y + row_heights[ri]], fill=rgb(COLORS["grid"]))
            x += cw
        draw.line([x, y, x, y + row_heights[ri]], fill=rgb(COLORS["grid"]))
        y += row_heights[ri]
    footer(draw, (width, height))
    img.save(path)


def line_chart(path: Path, title: str, subtitle: str, x: list[float], series: dict[str, list[float]], y_label: str) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 165, 1510, 760
    all_y = [v for vals in series.values() for v in vals]
    ymin, ymax = min(all_y), max(all_y)
    pad = max((ymax - ymin) * 0.08, 1e-9)
    ymin -= pad
    ymax += pad
    xmin, xmax = min(x), max(x)
    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)
    for i in range(6):
        yy = top + i * (bottom - top) / 5
        value = ymax - i * (ymax - ymin) / 5
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((48, yy - 12), f"{value:.2f}", fill=rgb(COLORS["muted"]), font=font(15))
    for i in range(6):
        xx = left + i * (right - left) / 5
        value = xmin + i * (xmax - xmin) / 5
        draw.text((xx - 26, bottom + 20), f"{value:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), "time (ms)", fill=rgb(COLORS["muted"]), font=font(17, True))
    draw.text((left - 110, top - 36), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))

    def xy(px: float, py: float) -> tuple[float, float]:
        return (
            left + (px - xmin) / (xmax - xmin) * (right - left),
            bottom - (py - ymin) / (ymax - ymin) * (bottom - top),
        )

    for idx, (name, values) in enumerate(series.items()):
        color = rgb(PALETTE[idx % len(PALETTE)])
        pts = [xy(px, py) for px, py in zip(x, values)]
        draw.line(pts, fill=color, width=4)
        for px, py in pts[:: max(1, len(pts) // 80)]:
            draw.ellipse([px - 3, py - 3, px + 3, py + 3], fill=color)
        lx = left + 18 + idx * 250
        draw.line([lx, 116, lx + 38, 116], fill=color, width=4)
        draw.text((lx + 48, 104), name, fill=rgb(COLORS["ink"]), font=font(16))
    footer(draw, img.size)
    img.save(path)


def bar_chart(path: Path, title: str, subtitle: str, labels: list[str], values: list[float], y_label: str) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 155, 1510, 760
    ymin, ymax = min(0, min(values)), max(values)
    pad = max((ymax - ymin) * 0.12, 1e-9)
    ymin -= pad
    ymax += pad
    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)

    def y_of(value: float) -> float:
        return bottom - (value - ymin) / (ymax - ymin) * (bottom - top)

    for i in range(6):
        val = ymin + i * (ymax - ymin) / 5
        yy = y_of(val)
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((48, yy - 12), f"{val:.2f}", fill=rgb(COLORS["muted"]), font=font(15))
    zero_y = y_of(0)
    draw.line([left, zero_y, right, zero_y], fill=rgb("#AAB5C4"), width=2)
    slot = (right - left) / len(values)
    bw = slot * 0.58
    for i, (label, val) in enumerate(zip(labels, values)):
        x0 = left + i * slot + (slot - bw) / 2
        y0 = y_of(val)
        draw.rectangle([x0, min(y0, zero_y), x0 + bw, max(y0, zero_y)], fill=rgb(PALETTE[i % len(PALETTE)]))
        draw.text((x0 + 8, min(y0, zero_y) - 28), f"{val:.3f}", fill=rgb(COLORS["ink"]), font=font(14, True))
        draw.text((x0 + bw / 2 - 8, bottom + 20), label, fill=rgb(COLORS["muted"]), font=font(18, True))
    draw.text((left - 112, top - 35), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))
    footer(draw, img.size)
    img.save(path)


def load_results() -> tuple[pd.DataFrame, dict[str, pd.DataFrame]]:
    summaries = []
    timeseries = {}
    for mode in MODES:
        summary_path = ROOT / "output" / f"{tag(mode)}_summary.csv"
        ts_path = ROOT / "output" / f"{tag(mode)}_timeseries.csv"
        if not summary_path.exists() or not ts_path.exists():
            raise FileNotFoundError(f"Missing dynamic sweep output for {mode}: {summary_path}")
        row = pd.read_csv(summary_path).iloc[0].to_dict()
        row["fg_mode"] = mode
        summaries.append(row)
        timeseries[mode] = pd.read_csv(ts_path)
    return pd.DataFrame(summaries), timeseries


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary, timeseries = load_results()
    summary = summary.set_index("fg_mode").loc[MODES].reset_index()

    for mode in MODES:
        for suffix in ["summary", "timeseries"]:
            src = ROOT / "output" / f"{tag(mode)}_{suffix}.csv"
            copy2(src, DATA_DIR / src.name)

    rows = []
    for row in summary.itertuples(index=False):
        rows.append([
            row.fg_mode,
            f"{row.static_center_mm:.4f}",
            f"{row.peak_center_mm:.4f}",
            f"{row.peak_time_s * 1000:.2f}",
            f"{row.overshoot_ratio:.3f}",
            f"{row.freq_01_Hz:.2f}",
            f"{row.theta_span_max_K:.4f}",
        ])
    table_image(
        FIG_DIR / "01_fg_dynamic_summary_table.png",
        "10x10 Newmark FG 分布动力摘要",
        ["FG", "静态中心(mm)", "动力峰值(mm)", "峰时(ms)", "超调", "一阶频率(Hz)", "θ跨度(K)"],
        rows,
        [90, 190, 190, 140, 120, 170, 150],
        "Vf0=0.6 / CFFF / Case A / 40 ms / dt=0.1 ms",
    )

    bar_chart(
        FIG_DIR / "02_peak_by_fg.png",
        "不同 FG 分布的动力峰值",
        "峰值绝对值用于比较功能梯度对瞬态挠度的放大作用",
        MODES,
        summary["peak_abs_center_mm"].tolist(),
        "|w| peak (mm)",
    )
    bar_chart(
        FIG_DIR / "03_static_by_fg.png",
        "不同 FG 分布的静态中心挠度",
        "作为动力超调倍率的基准",
        MODES,
        summary["static_center_mm"].tolist(),
        "static w (mm)",
    )
    x_ms = (timeseries[MODES[0]]["time_s"] * 1000).tolist()
    center_series = {mode: timeseries[mode]["w_center_mm"].tolist() for mode in MODES}
    theta_series = {mode: timeseries[mode]["theta_span_K"].tolist() for mode in MODES}
    line_chart(
        FIG_DIR / "04_center_timeseries_by_fg.png",
        "不同 FG 分布的中心挠度时程",
        "完整 Newmark pilot，比较相位、峰值与衰减差异",
        x_ms,
        center_series,
        "w (mm)",
    )
    line_chart(
        FIG_DIR / "05_theta_span_timeseries_by_fg.png",
        "不同 FG 分布的层温差跨度时程",
        "由 Newmark 位移响应回代热方程得到",
        x_ms,
        theta_series,
        "theta span (K)",
    )
    bar_chart(
        FIG_DIR / "06_frequency_by_fg.png",
        "不同 FG 分布的一阶频率",
        "用于解释动力峰值和相位差异",
        MODES,
        summary["freq_01_Hz"].tolist(),
        "f1 (Hz)",
    )

    best_peak = summary.loc[summary["peak_abs_center_mm"].idxmin()]
    worst_peak = summary.loc[summary["peak_abs_center_mm"].idxmax()]
    readme = f"""# 10x10 Newmark FG 分布动力扫描（2026-05-27）

本实验是在 30x30 非 U 分布直接装配出现内存峰值后，改用更稳的 10x10 完整 Newmark pilot 做新内容扩展。工况固定为 Vf0=0.6、CFFF、Case A 机械压力、40 ms 时程、dt=0.1 ms，比较 U/V/X/O/P 五种功能梯度分布。

## 1. 核心结果

| FG | 静态中心 mm | 动力峰值 mm | 峰值时间 ms | 超调倍数 | 一阶频率 Hz | 最大 θ 跨度 K |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
"""
    for row in summary.itertuples(index=False):
        readme += f"| {row.fg_mode} | {row.static_center_mm:.4f} | {row.peak_center_mm:.4f} | {row.peak_time_s * 1000:.2f} | {row.overshoot_ratio:.3f} | {row.freq_01_Hz:.2f} | {row.theta_span_max_K:.4f} |\n"

    readme += f"""
峰值绝对值最小的是 {best_peak.fg_mode}（{best_peak.peak_abs_center_mm:.4f} mm），最大的是 {worst_peak.fg_mode}（{worst_peak.peak_abs_center_mm:.4f} mm）。这组结果可作为后续 30x30 FG 分布模态实验的低成本先验。

![摘要](figures/01_fg_dynamic_summary_table.png)

## 2. 峰值与静态基准

![峰值](figures/02_peak_by_fg.png)

![静态](figures/03_static_by_fg.png)

## 3. 时程对比

![中心挠度](figures/04_center_timeseries_by_fg.png)

![温差跨度](figures/05_theta_span_timeseries_by_fg.png)

## 4. 频率对比

![频率](figures/06_frequency_by_fg.png)

## 5. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/*_summary.csv` | 各 FG 分布的峰值、频率、温差摘要 |
| `data/*_timeseries.csv` | 各 FG 分布的中心挠度和温差时程 |
| `figures/*.png` | 可直接截入 PPT 的图表 |
| `../../tools/generate_dynamic_10x10_cases.py` | 10x10 FG 输入文件生成 |
| `../../run_dynamic_representative.m` | Newmark pilot 入口 |
"""
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
