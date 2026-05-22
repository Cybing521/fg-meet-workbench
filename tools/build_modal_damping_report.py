#!/usr/bin/env python3
"""Build report assets for the 30x30 modal damping sensitivity run."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "2026-05-23-modal-damping"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README_PATH = REPORT_DIR / "README.md"

TAG = "dynamic_modal_30x30_U_Vf06_elastic_damping_sensitivity"
SUMMARY_CSV = ROOT / "output" / f"{TAG}_summary.csv"
MODES_CSV = ROOT / "output" / f"{TAG}_modes.csv"
TIMESERIES_CSV = ROOT / "output" / f"{TAG}_timeseries.csv"

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
    draw.text((42, size[1] - 32), "FG-MEET 30x30 modal damping sensitivity | 2026-05-23", fill=rgb(COLORS["muted"]), font=font(16))


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


def line_chart(
    path: Path,
    title: str,
    subtitle: str,
    x: list[float],
    series: dict[str, list[float]],
    x_label: str,
    y_label: str,
    x_fmt: str = "{:.1f}",
    y_fmt: str = "{:.2f}",
) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 165, 1510, 760
    all_y = [v for vals in series.values() for v in vals]
    ymin, ymax = min(all_y), max(all_y)
    pad = max((ymax - ymin) * 0.08, 1e-9)
    ymin -= pad
    ymax += pad
    xmin, xmax = min(x), max(x)
    if xmax == xmin:
        xmax = xmin + 1
    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)
    for i in range(6):
        yy = top + i * (bottom - top) / 5
        value = ymax - i * (ymax - ymin) / 5
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((48, yy - 12), y_fmt.format(value), fill=rgb(COLORS["muted"]), font=font(15))
    for i in range(6):
        xx = left + i * (right - left) / 5
        value = xmin + i * (xmax - xmin) / 5
        draw.text((xx - 26, bottom + 20), x_fmt.format(value), fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), x_label, fill=rgb(COLORS["muted"]), font=font(17, True))
    draw.text((left - 110, top - 36), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))

    def xy(px: float, py: float) -> tuple[float, float]:
        return (
            left + (px - xmin) / (xmax - xmin) * (right - left),
            bottom - (py - ymin) / (ymax - ymin) * (bottom - top),
        )

    palette = [COLORS["blue"], COLORS["orange"], COLORS["green"], COLORS["purple"], COLORS["teal"], COLORS["red"]]
    for idx, (name, values) in enumerate(series.items()):
        pts = [xy(px, py) for px, py in zip(x, values)]
        draw.line(pts, fill=rgb(palette[idx % len(palette)]), width=4)
        for px, py in pts:
            draw.ellipse([px - 4, py - 4, px + 4, py + 4], fill=rgb(palette[idx % len(palette)]))
        lx = left + 18 + (idx % 3) * 410
        ly = 112 + (idx // 3) * 28
        draw.line([lx, ly + 12, lx + 38, ly + 12], fill=rgb(palette[idx % len(palette)]), width=4)
        draw.text((lx + 48, ly), name, fill=rgb(COLORS["ink"]), font=font(16))
    footer(draw, img.size)
    img.save(path)


def damping_code(value: float) -> str:
    return f"{round(value * 10000):04d}"


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary = pd.read_csv(SUMMARY_CSV).sort_values("damping_ratio")
    modes = pd.read_csv(MODES_CSV)
    ts = pd.read_csv(TIMESERIES_CSV)
    for src in [SUMMARY_CSV, MODES_CSV, TIMESERIES_CSV]:
        copy2(src, DATA_DIR / src.name)

    rows = []
    for row in summary.itertuples(index=False):
        rows.append([
            f"{row.damping_ratio * 100:.2f}%",
            f"{int(row.n_modes)}",
            f"{row.peak_center_mm:.4f}",
            f"{row.peak_time_s * 1000:.2f}",
            f"{row.overshoot_ratio:.3f}",
            f"{row.final_center_mm:.4f}",
            f"{row.theta_span_max_K:.4f}",
        ])
    table_image(
        FIG_DIR / "01_damping_summary_table.png",
        "30x30 模态阻尼敏感性摘要",
        ["阻尼比", "阶数", "峰值(mm)", "峰时(ms)", "超调", "40ms位移(mm)", "θ跨度(K)"],
        rows,
        [150, 100, 170, 150, 120, 190, 160],
        "固定 16 阶模态，比较 0/0.5/0.8/1.5% 阻尼对峰值和衰减的影响",
    )

    x_damping = (summary["damping_ratio"] * 100).tolist()
    line_chart(
        FIG_DIR / "02_peak_vs_damping.png",
        "动力峰值随阻尼比变化",
        "阻尼越大，第一峰值和后续振动幅值越低",
        x_damping,
        {"peak abs": summary["peak_abs_center_mm"].tolist()},
        "damping ratio (%)",
        "|w| peak (mm)",
        x_fmt="{:.2f}",
        y_fmt="{:.3f}",
    )
    line_chart(
        FIG_DIR / "03_theta_span_vs_damping.png",
        "最大层温差跨度随阻尼比变化",
        "热响应由位移时程回代得到，因此随动力幅值同步变化",
        x_damping,
        {"theta span": summary["theta_span_max_K"].tolist()},
        "damping ratio (%)",
        "theta span (K)",
        x_fmt="{:.2f}",
        y_fmt="{:.3f}",
    )

    x_ms = (ts["time_s"] * 1000).tolist()
    center_series = {}
    theta_series = {}
    n_modes = int(summary["n_modes"].iloc[0])
    for row in summary.itertuples(index=False):
        code = damping_code(row.damping_ratio)
        label = f"{row.damping_ratio * 100:.1f}%"
        center_series[label] = ts[f"w_center_zeta_{code}_{n_modes:02d}_modes_mm"].tolist()
        theta_series[label] = ts[f"theta_span_zeta_{code}_{n_modes:02d}_modes_K"].tolist()
    line_chart(
        FIG_DIR / "04_center_timeseries_by_damping.png",
        "不同阻尼比中心挠度时程",
        "0% 为无阻尼基准，0.8% 为前序 30x30 模态默认口径",
        x_ms,
        center_series,
        "time (ms)",
        "w (mm)",
    )
    line_chart(
        FIG_DIR / "05_theta_span_timeseries_by_damping.png",
        "不同阻尼比层温差跨度时程",
        "阻尼越大，回代得到的层温差振荡幅值越低",
        x_ms,
        theta_series,
        "time (ms)",
        "theta span (K)",
    )

    first = summary.iloc[0]
    default = summary.iloc[(summary["damping_ratio"] - 0.008).abs().argmin()]
    high = summary.iloc[-1]
    verdict_rows = [
        ["无阻尼基准", f"峰值 {first.peak_center_mm:.4f} mm @ {first.peak_time_s * 1000:.2f} ms，接近 2×静态响应"],
        ["0.8% 默认口径", f"峰值 {default.peak_center_mm:.4f} mm，延续前序 30x30 模态结果"],
        ["1.5% 高阻尼", f"峰值 {high.peak_center_mm:.4f} mm，40 ms 位移 {high.final_center_mm:.4f} mm"],
        ["建议", "组会中保留 0.8% 作为当前主结果，同时展示阻尼敏感性说明峰值范围。"],
    ]
    table_image(
        FIG_DIR / "06_damping_assessment_table.png",
        "阻尼敏感性判断",
        ["项目", "说明"],
        verdict_rows,
        [260, 980],
        "用于说明当前默认阻尼选择，以及后续论文最终图的参数依据",
    )

    readme = f"""# 30x30 模态阻尼敏感性分析（2026-05-23）

本报告在阶数敏感性之后继续补充阻尼比检查。计算固定 16 阶模态，分别取 {', '.join(f'{v*100:.2f}%' for v in summary['damping_ratio'])} 阻尼比，输出中心挠度、层温差跨度和峰值摘要。

## 1. 核心结果

| 阻尼比 | 峰值 mm | 峰值时间 ms | 超调倍数 | 40 ms 位移 mm | 最大 θ 跨度 K |
| --- | ---: | ---: | ---: | ---: | ---: |
"""
    for row in summary.itertuples(index=False):
        readme += f"| {row.damping_ratio * 100:.2f}% | {row.peak_center_mm:.4f} | {row.peak_time_s * 1000:.2f} | {row.overshoot_ratio:.3f} | {row.final_center_mm:.4f} | {row.theta_span_max_K:.4f} |\n"

    readme += f"""
![阻尼摘要](figures/01_damping_summary_table.png)

## 2. 趋势图

![峰值随阻尼变化](figures/02_peak_vs_damping.png)

![温差跨度随阻尼变化](figures/03_theta_span_vs_damping.png)

## 3. 时程图

![中心挠度时程](figures/04_center_timeseries_by_damping.png)

![温差跨度时程](figures/05_theta_span_timeseries_by_damping.png)

## 4. 讨论口径

![阻尼判断](figures/06_damping_assessment_table.png)

当前建议：论文或组会主图仍可沿用 0.8% 阻尼；同时展示无阻尼到 1.5% 的范围，说明动力峰值对阻尼的敏感程度。若后续需要最终论文图，建议再把阻尼取值与材料/结构实验或文献区间对齐。

## 5. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/{SUMMARY_CSV.name}` | 各阻尼比峰值、超调、温差和运行时间 |
| `data/{TIMESERIES_CSV.name}` | 各阻尼比中心挠度和层温差时程 |
| `data/{MODES_CSV.name}` | 16 阶模态频率和静态贡献 |
| `figures/*.png` | 可直接截取进 PPT 的阻尼敏感性图片 |
| `../../run_dynamic_modal_sensitivity_30x30.m` | 支持多阻尼比的一次装配计算入口 |
"""
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
