#!/usr/bin/env python3
"""Build report assets for the 30x30 modal-order sensitivity run."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT / "reports" / "2026-05-22-modal-sensitivity"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README_PATH = REPORT_DIR / "README.md"

TAG = "dynamic_modal_30x30_U_Vf06_elastic_sensitivity"
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
    draw.text((42, size[1] - 32), "FG-MEET 30x30 modal sensitivity | 2026-05-22", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(
    path: Path,
    title: str,
    headers: list[str],
    rows: list[list[object]],
    col_widths: list[int],
    subtitle: str = "",
) -> None:
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
    static_value: float | None = None,
    x_fmt: str = "{:.1f}",
    y_fmt: str = "{:.2f}",
) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 165, 1510, 760
    all_y = [v for vals in series.values() for v in vals]
    if static_value is not None:
        all_y.append(static_value)
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
        lx = left + 18 + (idx % 3) * 420
        ly = 112 + (idx // 3) * 28
        draw.line([lx, ly + 12, lx + 38, ly + 12], fill=rgb(palette[idx % len(palette)]), width=4)
        draw.text((lx + 48, ly), name, fill=rgb(COLORS["ink"]), font=font(16))
    if static_value is not None:
        _, sy = xy(xmin, static_value)
        draw.line([left, sy, right, sy], fill=rgb(COLORS["red"]), width=3)
        draw.text((right - 285, sy - 25), f"mechanical static {static_value:.3f}", fill=rgb(COLORS["red"]), font=font(16, True))
    footer(draw, img.size)
    img.save(path)


def bar_chart(
    path: Path,
    title: str,
    subtitle: str,
    labels: list[str],
    values: list[float],
    y_label: str,
    signed: bool = False,
    value_fmt: str = "{:.2f}",
) -> None:
    img, draw = canvas(title, subtitle)
    left, top, right, bottom = 150, 155, 1510, 760
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
        if i % 2 == 0 or len(values) <= 10:
            draw.text((x0 - 6, min(y0, zero_y) - 26), value_fmt.format(val), fill=rgb(COLORS["ink"]), font=font(12, True))
        draw.text((x0 + 4, bottom + 20), label, fill=rgb(COLORS["muted"]), font=font(14))
    draw.text((left - 112, top - 35), y_label, fill=rgb(COLORS["muted"]), font=font(17, True))
    footer(draw, img.size)
    img.save(path)


def fmt_signed(value: float, suffix: str) -> str:
    return f"{value:+.4f}{suffix}"


def build() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    summary = pd.read_csv(SUMMARY_CSV)
    modes = pd.read_csv(MODES_CSV)
    ts = pd.read_csv(TIMESERIES_CSV)

    for src in [SUMMARY_CSV, MODES_CSV, TIMESERIES_CSV]:
        copy2(src, DATA_DIR / src.name)

    mode_counts = summary["n_modes"].astype(int).tolist()
    max_row = summary.iloc[-1]
    max_modes = int(max_row.n_modes)
    runtime_min = float(max_row.total_runtime_s) / 60.0

    rows = []
    for row in summary.itertuples(index=False):
        rows.append(
            [
                f"{int(row.n_modes)}",
                f"{row.modal_capture_ratio:.6f}",
                f"{row.modal_static_center_mm:.4f}",
                f"{row.peak_center_mm:.4f}",
                f"{row.peak_time_s * 1000:.2f}",
                f"{row.overshoot_ratio:.3f}",
                f"{row.theta_span_max_K:.4f}",
                f"{fmt_signed(row.peak_abs_delta_vs_max_mm, ' mm')} / {fmt_signed(row.theta_span_delta_vs_max_K, ' K')}",
            ]
        )
    table_image(
        FIG_DIR / "01_modal_sensitivity_summary_table.png",
        "30x30 模态阶数敏感性摘要",
        ["阶数", "静态捕获", "模态静态(mm)", "峰值(mm)", "峰时(ms)", "超调", "θ跨度(K)", f"相对{max_modes}阶"],
        rows,
        [100, 170, 190, 170, 140, 120, 150, 260],
        f"一次装配求到 {max_modes} 阶，分别保留 {', '.join(map(str, mode_counts))} 阶恢复时程",
    )

    x_modes = [float(v) for v in mode_counts]
    line_chart(
        FIG_DIR / "02_capture_ratio_vs_modes.png",
        "静态捕获比例随模态阶数变化",
        "捕获比例接近 1 表明保留模态已能恢复机械静态中心挠度",
        x_modes,
        {"capture ratio": summary["modal_capture_ratio"].tolist()},
        "retained modes",
        "ratio",
        x_fmt="{:.0f}",
        y_fmt="{:.4f}",
    )
    line_chart(
        FIG_DIR / "03_peak_vs_modes.png",
        "动力峰值随模态阶数变化",
        "用峰值绝对值检查 8 阶、12 阶、16 阶之间的收敛趋势",
        x_modes,
        {"peak abs": summary["peak_abs_center_mm"].tolist()},
        "retained modes",
        "|w| peak (mm)",
        x_fmt="{:.0f}",
        y_fmt="{:.3f}",
    )

    x_ms = (ts["time_s"] * 1000).tolist()
    center_series = {
        f"{n} modes": ts[f"w_center_{n:02d}_modes_mm"].tolist()
        for n in mode_counts
    }
    theta_series = {
        f"{n} modes": ts[f"theta_span_{n:02d}_modes_K"].tolist()
        for n in mode_counts
    }
    line_chart(
        FIG_DIR / "04_center_timeseries_by_modes.png",
        "不同模态阶数的中心挠度时程",
        "曲线越重合，说明动力时程对更高阶模态越不敏感",
        x_ms,
        center_series,
        "time (ms)",
        "w (mm)",
        static_value=float(max_row.mechanical_static_center_mm),
    )
    line_chart(
        FIG_DIR / "05_theta_span_timeseries_by_modes.png",
        "不同模态阶数的层温差跨度时程",
        "温度响应由位移时程回代 Ktt 热方程得到",
        x_ms,
        theta_series,
        "time (ms)",
        "theta span (K)",
    )

    first_modes = modes.head(max_modes)
    labels = [f"m{int(m)}" for m in first_modes["mode"]]
    bar_chart(
        FIG_DIR / "06_first16_modal_contribution.png",
        "前 16 阶对中心静态位移的贡献",
        "一阶贡献占主导，高阶主要用于修正局部动态峰值和相位",
        labels,
        first_modes["center_static_contribution_mm"].tolist(),
        "mm",
        signed=True,
    )
    bar_chart(
        FIG_DIR / "07_first16_frequency_bar.png",
        "30x30 前 16 阶固有频率",
        "用于说明时程覆盖的频率范围和模态截断口径",
        labels,
        first_modes["freq_Hz"].tolist(),
        "Hz",
        value_fmt="{:.0f}",
    )

    verdict_rows = [
        ["计算口径", f"30x30 全模型一次装配，求前 {max_modes} 阶；每组阶数单独恢复 w(t) 与 θ(t)"],
        ["与 8 阶相比", f"{max_modes} 阶峰值变化 {summary.iloc[2].peak_abs_center_mm - max_row.peak_abs_center_mm:+.4f} mm，θ跨度变化 {summary.iloc[2].theta_span_max_K - max_row.theta_span_max_K:+.4f} K"],
        ["最高阶结果", f"{max_modes} 阶峰值 {max_row.peak_center_mm:.4f} mm @ {max_row.peak_time_s * 1000:.2f} ms，θ跨度 {max_row.theta_span_max_K:.4f} K"],
        ["建议", "汇报中可把 16 阶作为当前更稳妥结果，同时保留 8 阶作为前期阶段性结果；论文最终可再补阻尼敏感性和长时程 Newmark 对照。"],
        ["总计算时长", f"{runtime_min:.2f} min；其中装配 {float(max_row.assembly_runtime_s) / 60:.2f} min，求模态 {float(max_row.eigs_runtime_s) / 60:.2f} min"],
    ]
    table_image(
        FIG_DIR / "08_convergence_assessment_table.png",
        "模态阶数收敛性判断",
        ["项目", "说明"],
        verdict_rows,
        [260, 980],
        "用于组会说明：为何继续补算更高阶模态，以及当前结果是否可信",
    )

    readme = f"""# 30x30 模态阶数敏感性分析（2026-05-22）

本报告是在 30x30 8 阶模态动力结果之后补充的收敛性检查。计算方式为：30x30 模型只装配一次，只求一次前 {max_modes} 阶固有模态，然后分别保留 {', '.join(map(str, mode_counts))} 阶重构中心挠度时程，并通过 `Ktt \\ (-Ktu*u)` 回代得到层温差跨度。

## 1. 核心结论

| 阶数 | 静态捕获比例 | 动力峰值 mm | 峰值时间 ms | 超调倍数 | 最大 θ 跨度 K |
| --- | ---: | ---: | ---: | ---: | ---: |
"""
    for row in summary.itertuples(index=False):
        readme += f"| {int(row.n_modes)} | {row.modal_capture_ratio:.6f} | {row.peak_center_mm:.4f} | {row.peak_time_s * 1000:.2f} | {row.overshoot_ratio:.3f} | {row.theta_span_max_K:.4f} |\n"

    readme += f"""
最高阶（{max_modes} 阶）当前结果为：峰值 {max_row.peak_center_mm:.4f} mm，峰值时间 {max_row.peak_time_s * 1000:.2f} ms，最大层温差跨度 {max_row.theta_span_max_K:.4f} K。与 8 阶相比，{max_modes} 阶峰值绝对值变化 {summary.iloc[2].peak_abs_center_mm - max_row.peak_abs_center_mm:+.4f} mm，最大 θ 跨度变化 {summary.iloc[2].theta_span_max_K - max_row.theta_span_max_K:+.4f} K。

![敏感性摘要](figures/01_modal_sensitivity_summary_table.png)

## 2. 收敛趋势

![静态捕获比例](figures/02_capture_ratio_vs_modes.png)

![动力峰值](figures/03_peak_vs_modes.png)

## 3. 时程对比

![中心挠度时程](figures/04_center_timeseries_by_modes.png)

![温差跨度时程](figures/05_theta_span_timeseries_by_modes.png)

## 4. 模态信息

![模态贡献](figures/06_first16_modal_contribution.png)

![固有频率](figures/07_first16_frequency_bar.png)

## 5. 组会讨论口径

![收敛性判断](figures/08_convergence_assessment_table.png)

当前建议：把 {max_modes} 阶作为 30x30 模态降阶的更稳妥结果展示，8 阶作为阶段性快速结果保留。后续如继续追论文最终图，可补阻尼比敏感性（例如 0、0.5%、0.8%、1.5%）和夜间长时程 Newmark 对照。

## 6. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/{TIMESERIES_CSV.name}` | 不同阶数的中心挠度、温差跨度和 10 层温度时程 |
| `data/{SUMMARY_CSV.name}` | 各阶数峰值、超调、静态捕获比例与运行时间 |
| `data/{MODES_CSV.name}` | 前 {max_modes} 阶频率、模态力、中心静态贡献 |
| `figures/*.png` | 可直接截取进 PPT 的图片 |
| `../../run_dynamic_modal_sensitivity_30x30.m` | 本次敏感性计算入口 |
"""
    README_PATH.write_text(readme, encoding="utf-8")
    print(f"Wrote {README_PATH}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
