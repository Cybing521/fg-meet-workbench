#!/usr/bin/env python3
"""Build a small dynamic-result report from the Newmark pilot CSV files."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "2026-05-22-dynamic"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README_PATH = REPORT_DIR / "README.md"
SUMMARY_CSV = ROOT / "output" / "dynamic_U_Vf06_elastic_10x10_summary.csv"
TIMESERIES_CSV = ROOT / "output" / "dynamic_U_Vf06_elastic_10x10_timeseries.csv"

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
    draw.text((42, size[1] - 32), "FG-MEET Workbench dynamic pilot | 2026-05-22", fill=rgb(COLORS["muted"]), font=font(16))


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

    palette = [COLORS["blue"], COLORS["orange"], COLORS["green"], COLORS["red"]]
    for idx, (name, values) in enumerate(series.items()):
        pts = [xy(px, py) for px, py in zip(x, values)]
        draw.line(pts, fill=rgb(palette[idx % len(palette)]), width=4)
        lx = left + 20 + idx * 220
        draw.line([lx, 112, lx + 36, 112], fill=rgb(palette[idx % len(palette)]), width=4)
        draw.text((lx + 46, 100), name, fill=rgb(COLORS["ink"]), font=font(17))
    if static_value is not None:
        _, sy = xy(xmin, static_value)
        draw.line([left, sy, right, sy], fill=rgb(COLORS["red"]), width=3)
        draw.text((right - 190, sy - 25), f"static {static_value:.3f}", fill=rgb(COLORS["red"]), font=font(16, True))
    footer(draw, img.size)
    img.save(path)


def bar_chart(path: Path, title: str, subtitle: str, labels: list[str], values: list[float], y_label: str) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 150, 1510, 760
    ymax = max(values) * 1.12
    draw.rectangle([left, top, right, bottom], outline=rgb(COLORS["grid"]), width=2)
    for i in range(6):
        yy = bottom - i * (bottom - top) / 5
        val = i * ymax / 5
        draw.line([left, yy, right, yy], fill=rgb("#EEF2F6"))
        draw.text((48, yy - 12), f"{val:.0f}", fill=rgb(COLORS["muted"]), font=font(15))
    slot = (right - left) / len(values)
    bw = slot * 0.58
    for i, (label, val) in enumerate(zip(labels, values)):
        x0 = left + i * slot + (slot - bw) / 2
        y0 = bottom - val / ymax * (bottom - top)
        draw.rectangle([x0, y0, x0 + bw, bottom], fill=rgb(COLORS["blue"]))
        draw.text((x0 + 8, y0 - 28), f"{val:.1f}", fill=rgb(COLORS["ink"]), font=font(16, True))
        draw.text((x0 + 12, bottom + 20), label, fill=rgb(COLORS["muted"]), font=font(16))
    draw.text((left - 100, top - 35), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))
    footer(draw, img.size)
    img.save(path)


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary = pd.read_csv(SUMMARY_CSV).iloc[0]
    ts = pd.read_csv(TIMESERIES_CSV)
    copy2(SUMMARY_CSV, DATA_DIR / SUMMARY_CSV.name)
    copy2(TIMESERIES_CSV, DATA_DIR / TIMESERIES_CSV.name)

    decision_rows = [
        ["30x30 直接 Newmark", "已尝试", "1 ms 冒烟测试超过 5 min，未产出时程", "不作为交互式下一步，改为长任务或降阶"],
        ["10x10 Newmark pilot", "已完成", "401 步，40 ms，约 22 s 完成", "用于验证流程和汇报动力趋势"],
        ["30x30 模态降阶", "建议下一步", "保留 30x30 空间精度，先求前 6-10 阶模态", "比全量 Newmark 更适合今晚推进"],
        ["30x30 全量 Newmark", "后续长任务", "需缓存矩阵、减少日志、可能夜间运行", "作为论文级最终补充"],
    ]
    table_image(FIG_DIR / "01_dynamic_strategy_table.png", "下一步动力计算策略", ["方案", "状态", "证据", "处理建议"], decision_rows, [250, 170, 470, 500])

    summary_rows = [
        ["模型", "U / Vf0=0.6 / CFFF / 10x10 / 10 层"],
        ["载荷", "Case A 机械阶跃压力 -15000"],
        ["时间步", f"{summary.dt_s:.4g} s"],
        ["总时长/步数", f"{summary.total_s:.3f} s / {int(summary.steps)} 步"],
        ["静态中心挠度", f"{summary.static_center_mm:.4f} mm"],
        ["动力峰值", f"{summary.peak_center_mm:.4f} mm @ {summary.peak_time_s*1000:.2f} ms"],
        ["超调倍数", f"{summary.overshoot_ratio:.3f} x static"],
        ["最大温差跨度", f"{summary.theta_span_max_K:.4f} K"],
        ["第一阶频率", f"{summary.freq_01_Hz:.2f} Hz"],
    ]
    table_image(FIG_DIR / "02_dynamic_summary_table.png", "10x10 Newmark 动力结果摘要", ["指标", "数值"], summary_rows, [360, 940])

    x_ms = (ts["time_s"] * 1000).tolist()
    line_chart(
        FIG_DIR / "03_center_displacement_timeseries.png",
        "中心挠度动力时程",
        "10x10 pilot, undamped step Newmark; 红线为同一模型静态解",
        x_ms,
        {"w_center": ts["w_center_mm"].tolist()},
        "w (mm)",
        static_value=float(summary.static_center_mm),
    )
    line_chart(
        FIG_DIR / "04_theta_span_timeseries.png",
        "层温差跨度时程",
        "由动态位移回代热方程得到的 10 层温差跨度",
        x_ms,
        {"theta_span": ts["theta_span_K"].tolist()},
        "theta span (K)",
    )
    labels = [f"f{i}" for i in range(1, 7)]
    freqs = [float(summary[f"freq_{i:02d}_Hz"]) for i in range(1, 7)]
    bar_chart(FIG_DIR / "05_modal_frequency_bar.png", "前六阶频率估计", "用于决定动态时间步与总时长", labels, freqs, "Hz")

    readme = f"""# 动力代表算例结果补充（2026-05-22）

本页是静力/COMSOL 汇报之后的下一步结果：先用已有 Newmark 动力函数跑通一个可复现的代表算例，并记录为什么 30x30 全量动态不适合作为交互式计算入口。

## 1. 结论

| 项目 | 结果 |
| --- | --- |
| 当前可用结果 | 10x10 / U / Vf0=0.6 / CFFF / Case A 阶跃动力响应 |
| 计算规模 | 401 步，0.1 ms 步长，总时长 40 ms |
| 静态中心挠度 | {summary.static_center_mm:.4f} mm |
| 动力峰值 | {summary.peak_center_mm:.4f} mm，出现在 {summary.peak_time_s * 1000:.2f} ms |
| 超调倍数 | {summary.overshoot_ratio:.3f} × 静态挠度 |
| 最大温差跨度 | {summary.theta_span_max_K:.4f} K |
| 第一阶频率 | {summary.freq_01_Hz:.2f} Hz |

![策略表](figures/01_dynamic_strategy_table.png)

![摘要表](figures/02_dynamic_summary_table.png)

## 2. 结果图

![中心挠度时程](figures/03_center_displacement_timeseries.png)

![温差跨度时程](figures/04_theta_span_timeseries.png)

![前六阶频率](figures/05_modal_frequency_bar.png)

## 3. 如何继续

当前 10x10 结果用于证明动态入口、中心自由度映射、时程输出和热响应回代都已经打通。30x30 全量 Newmark 冒烟测试在 1 ms 时程下超过 5 分钟未完成，因此下一步建议走“30x30 模态降阶”：保留 30x30 的空间模型，先求前 6-10 阶模态，再用模态叠加生成中心时程。这样比每步直接解 13800 自由度全矩阵更适合今晚继续产出。

## 4. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/{TIMESERIES_CSV.name}` | 401 步中心挠度和 10 层温差时程 |
| `data/{SUMMARY_CSV.name}` | 峰值、超调、频率等摘要 |
| `figures/*.png` | 可直接截入 PPT 的结果图 |
| `../../run_dynamic_representative.m` | 动态代表算例统一入口 |
"""
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
