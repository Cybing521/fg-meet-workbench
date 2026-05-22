#!/usr/bin/env python3
"""Build a report for the 30x30 modal-superposition dynamic result."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "2026-05-22-modal30x30"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README_PATH = REPORT_DIR / "README.md"

SUMMARY_CSV = ROOT / "output" / "dynamic_modal_30x30_U_Vf06_elastic_8modes_summary.csv"
MODES_CSV = ROOT / "output" / "dynamic_modal_30x30_U_Vf06_elastic_8modes_modes.csv"
TIMESERIES_CSV = ROOT / "output" / "dynamic_modal_30x30_U_Vf06_elastic_8modes_timeseries.csv"
PILOT_SUMMARY_CSV = ROOT / "output" / "dynamic_U_Vf06_elastic_10x10_summary.csv"
PILOT_TIMESERIES_CSV = ROOT / "output" / "dynamic_U_Vf06_elastic_10x10_timeseries.csv"

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
    draw.rectangle([0, 0, size[0], 86], fill=rgb("#F1F5FA"))
    draw.text((42, 20), title, fill=rgb(COLORS["navy"]), font=font(34, True))
    if subtitle:
        draw.text((42, 58), subtitle, fill=rgb(COLORS["muted"]), font=font(18))
    return img, draw


def footer(draw: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
    draw.line([42, size[1] - 44, size[0] - 42, size[1] - 44], fill=rgb("#E1E7EF"), width=2)
    draw.text((42, size[1] - 32), "FG-MEET 30x30 modal dynamic | 2026-05-22", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(path: Path, title: str, headers: list[str], rows: list[list[object]], col_widths: list[int], subtitle: str = "") -> None:
    width = max(1500, sum(col_widths) + 120)
    tmp = Image.new("RGB", (width, 2000), "white")
    dtmp = ImageDraw.Draw(tmp)
    f_head = font(20, True)
    f_body = font(18)
    row_heights = []
    for row in rows:
        max_lines = 1
        for value, cw in zip(row, col_widths):
            max_lines = max(max_lines, len(wrap(dtmp, value, f_body, cw - 24)))
        row_heights.append(max(54, 24 + max_lines * 30))
    height = 150 + 58 + sum(row_heights) + 70
    img, draw = canvas(title, subtitle, (width, height))
    x0, y = 42, 118
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
                yy += 30
            draw.line([x, y, x, y + row_heights[ri]], fill=rgb(COLORS["grid"]))
            x += cw
        draw.line([x, y, x, y + row_heights[ri]], fill=rgb(COLORS["grid"]))
        y += row_heights[ri]
    footer(draw, (width, height))
    img.save(path)


def line_chart(path: Path, title: str, subtitle: str, x: list[float], series: dict[str, list[float]], y_label: str, static_value: float | None = None) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 150, 1510, 760
    all_y = [v for vals in series.values() for v in vals]
    if static_value is not None:
        all_y.append(static_value)
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
        draw.text((42, yy - 12), f"{value:.2f}", fill=rgb(COLORS["muted"]), font=font(15))
    for i in range(6):
        xx = left + i * (right - left) / 5
        value = xmin + i * (xmax - xmin) / 5
        draw.text((xx - 24, bottom + 20), f"{value:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), "time (ms)", fill=rgb(COLORS["muted"]), font=font(17, True))
    draw.text((left - 110, top - 36), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))

    def xy(px: float, py: float) -> tuple[float, float]:
        return (
            left + (px - xmin) / (xmax - xmin) * (right - left),
            bottom - (py - ymin) / (ymax - ymin) * (bottom - top),
        )

    palette = [COLORS["blue"], COLORS["orange"], COLORS["green"], COLORS["purple"]]
    for idx, (name, values) in enumerate(series.items()):
        pts = [xy(px, py) for px, py in zip(x, values)]
        draw.line(pts, fill=rgb(palette[idx % len(palette)]), width=4)
        lx = left + 20 + idx * 260
        draw.line([lx, 112, lx + 36, 112], fill=rgb(palette[idx % len(palette)]), width=4)
        draw.text((lx + 46, 100), name, fill=rgb(COLORS["ink"]), font=font(17))
    if static_value is not None:
        _, sy = xy(xmin, static_value)
        draw.line([left, sy, right, sy], fill=rgb(COLORS["red"]), width=3)
        draw.text((right - 245, sy - 25), f"mechanical static {static_value:.3f}", fill=rgb(COLORS["red"]), font=font(16, True))
    footer(draw, img.size)
    img.save(path)


def bar_chart(path: Path, title: str, subtitle: str, labels: list[str], values: list[float], y_label: str, signed: bool = False) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 150, 1510, 760
    if signed:
        vmax = max(abs(v) for v in values) * 1.12
        ymin, ymax = -vmax, vmax
    else:
        ymin, ymax = 0, max(values) * 1.12
    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)

    def y_of(val: float) -> float:
        return bottom - (val - ymin) / (ymax - ymin) * (bottom - top)

    for i in range(6):
        val = ymin + i * (ymax - ymin) / 5
        yy = y_of(val)
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((48, yy - 12), f"{val:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    zero_y = y_of(0)
    draw.line([left, zero_y, right, zero_y], fill=rgb("#AAB5C4"), width=2)
    slot = (right - left) / len(values)
    bw = slot * 0.58
    for i, (label, val) in enumerate(zip(labels, values)):
        x0 = left + i * slot + (slot - bw) / 2
        y0 = y_of(val)
        fill = COLORS["blue"] if val >= 0 else COLORS["orange"]
        draw.rectangle([x0, min(y0, zero_y), x0 + bw, max(y0, zero_y)], fill=rgb(fill))
        draw.text((x0 + 3, min(y0, zero_y) - 28), f"{val:.2f}", fill=rgb(COLORS["ink"]), font=font(14, True))
        draw.text((x0 + 12, bottom + 20), label, fill=rgb(COLORS["muted"]), font=font(16))
    draw.text((left - 112, top - 35), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))
    footer(draw, img.size)
    img.save(path)


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary = pd.read_csv(SUMMARY_CSV).iloc[0]
    modes = pd.read_csv(MODES_CSV)
    ts = pd.read_csv(TIMESERIES_CSV)
    pilot_summary = pd.read_csv(PILOT_SUMMARY_CSV).iloc[0]
    pilot_ts = pd.read_csv(PILOT_TIMESERIES_CSV)

    for src in [SUMMARY_CSV, MODES_CSV, TIMESERIES_CSV]:
        copy2(src, DATA_DIR / src.name)

    summary_rows = [
        ["模型", "30x30 / U / Vf0=0.6 / CFFF / 10 层"],
        ["方法", f"{int(summary.n_modes)} 阶机械模态叠加 + Ktt 回代热响应"],
        ["计算时长", "约 7.6 min，明显短于 30x30 全量 Newmark"],
        ["耦合静态中心挠度", f"{summary.coupled_static_center_mm:.4f} mm"],
        ["机械静态中心挠度", f"{summary.mechanical_static_center_mm:.4f} mm"],
        ["模态静态捕获", f"{summary.modal_static_center_mm:.4f} mm，比例 {summary.modal_capture_ratio:.6f}"],
        ["动力峰值", f"{summary.peak_center_mm:.4f} mm @ {summary.peak_time_s*1000:.2f} ms"],
        ["超调倍数", f"{summary.overshoot_ratio:.3f} x mechanical static"],
        ["最大温差跨度", f"{summary.theta_span_max_K:.4f} K"],
        ["第一阶频率", f"{summary.freq_01_Hz:.2f} Hz"],
    ]
    table_image(FIG_DIR / "01_modal30x30_summary_table.png", "30x30 模态降阶结果摘要", ["指标", "数值"], summary_rows, [380, 940])

    x_ms = (ts["time_s"] * 1000).tolist()
    line_chart(
        FIG_DIR / "02_modal30x30_center_timeseries.png",
        "30x30 中心挠度模态时程",
        "8 阶模态叠加，阻尼比 0.8%，红线为机械静态解",
        x_ms,
        {"30x30 modal": ts["w_center_mm"].tolist()},
        "w (mm)",
        static_value=float(summary.mechanical_static_center_mm),
    )
    line_chart(
        FIG_DIR / "03_modal30x30_theta_timeseries.png",
        "30x30 层温差跨度时程",
        "由模态位移时程回代 Ktt 热方程得到",
        x_ms,
        {"theta span": ts["theta_span_K"].tolist()},
        "theta span (K)",
    )
    labels = [f"m{int(m)}" for m in modes["mode"]]
    bar_chart(
        FIG_DIR / "04_modal_static_contribution.png",
        "各阶模态对中心静态位移的贡献",
        "m1 主导，前 8 阶合计捕获机械静态解约 100.04%",
        labels,
        modes["center_static_contribution_mm"].tolist(),
        "mm",
        signed=True,
    )
    bar_chart(
        FIG_DIR / "05_modal_frequency_bar.png",
        "30x30 前八阶频率",
        "用于确认 40 ms 时程覆盖一阶振动周期",
        labels,
        modes["freq_Hz"].tolist(),
        "Hz",
    )
    common = min(len(ts), len(pilot_ts))
    line_chart(
        FIG_DIR / "06_10x10_vs_30x30_center.png",
        "10x10 Newmark 与 30x30 模态时程对比",
        "30x30 采用 8 阶模态；10x10 为完整 Newmark pilot",
        x_ms[:common],
        {
            "30x30 modal": ts["w_center_mm"].iloc[:common].tolist(),
            "10x10 Newmark": pilot_ts["w_center_mm"].iloc[:common].tolist(),
        },
        "w (mm)",
    )

    readme = f"""# 30x30 模态降阶动力结果（2026-05-22）

本结果是在 10x10 Newmark pilot 之后继续推进的 30x30 动力计算。直接 30x30 全量 Newmark 在 1 ms 冒烟测试中超过 5 分钟未产出时程，因此这里采用 30x30 机械模态叠加：先求前 8 阶，再由模态响应重构中心挠度，并回代热方程得到层温差。

## 1. 核心结论

| 项目 | 结果 |
| --- | --- |
| 计算方法 | 30x30 全模型 + 8 阶模态叠加 + 热响应回代 |
| 计算时长 | 约 7.6 min |
| 耦合静态中心挠度 | {summary.coupled_static_center_mm:.4f} mm |
| 机械静态中心挠度 | {summary.mechanical_static_center_mm:.4f} mm |
| 模态静态捕获 | {summary.modal_static_center_mm:.4f} mm，捕获比例 {summary.modal_capture_ratio:.6f} |
| 动力峰值 | {summary.peak_center_mm:.4f} mm，出现在 {summary.peak_time_s * 1000:.2f} ms |
| 超调倍数 | {summary.overshoot_ratio:.3f} × 机械静态解 |
| 最大温差跨度 | {summary.theta_span_max_K:.4f} K |
| 第一阶频率 | {summary.freq_01_Hz:.2f} Hz |

![摘要表](figures/01_modal30x30_summary_table.png)

## 2. 时程与模态

![中心挠度时程](figures/02_modal30x30_center_timeseries.png)

![温差跨度时程](figures/03_modal30x30_theta_timeseries.png)

![模态贡献](figures/04_modal_static_contribution.png)

![前八阶频率](figures/05_modal_frequency_bar.png)

## 3. 与 10x10 pilot 对比

![对比](figures/06_10x10_vs_30x30_center.png)

10x10 Newmark 和 30x30 模态的第一阶频率非常接近：10x10 为 {pilot_summary.freq_01_Hz:.2f} Hz，30x30 为 {summary.freq_01_Hz:.2f} Hz。差异主要来自方法口径：10x10 pilot 是完整 Newmark、无阻尼；30x30 模态结果使用 0.8% 阻尼并保留前 8 阶，峰值更适合作为 30x30 后续论文图的基础版本。

## 4. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/{TIMESERIES_CSV.name}` | 401 步中心挠度与 10 层温差时程 |
| `data/{SUMMARY_CSV.name}` | 峰值、静态捕获、频率等摘要 |
| `data/{MODES_CSV.name}` | 前 8 阶频率和中心位移贡献 |
| `figures/*.png` | 可直接截入 PPT 的图片 |
| `../../run_dynamic_modal_30x30.m` | 30x30 模态降阶动力入口 |
"""
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
