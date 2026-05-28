#!/usr/bin/env python3
"""Build report assets for the porous static FG-MEE sweep."""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "output" / "results_static_porous.csv"
REPORT_DIR = ROOT / "reports" / "2026-05-28-porous-static"
FIG_DIR = REPORT_DIR / "figures"
DATA_DIR = REPORT_DIR / "data"
README = REPORT_DIR / "README.md"

EXPECTED_ROWS = 390
FG_MODES = ["U", "X"]
POROSITY_MODES = ["Even", "Uneven", "LogUneven"]
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
    "Even": COLORS["blue"],
    "Uneven": COLORS["green"],
    "LogUneven": COLORS["orange"],
    "U": COLORS["purple"],
    "X": COLORS["teal"],
}


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT), size=size)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
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
    draw.text((42, size[1] - 32), "FG-MEET porous static sweep | 2026-05-28", fill=rgb(COLORS["muted"]), font=font(16))


def table_image(path: Path, title: str, headers: list[str], rows: list[list[object]], col_widths: list[int], subtitle: str = "") -> None:
    width = max(1500, sum(col_widths) + 120)
    height = 154 + 58 + max(1, len(rows)) * 56 + 72
    img, draw = canvas(title, subtitle, (width, height))
    x0, y = 42, 122
    draw.rectangle([x0, y, x0 + sum(col_widths), y + 58], fill=rgb("#E6ECF3"), outline=rgb(COLORS["grid"]))
    x = x0
    for header, cw in zip(headers, col_widths):
        draw.text((x + 12, y + 17), header, fill=rgb(COLORS["navy"]), font=font(18, True))
        draw.line([x, y, x, y + 58 + max(1, len(rows)) * 56], fill=rgb(COLORS["grid"]))
        x += cw
    draw.line([x, y, x, y + 58 + max(1, len(rows)) * 56], fill=rgb(COLORS["grid"]))
    y += 58
    for ri, row in enumerate(rows):
        fill = "#FFFFFF" if ri % 2 == 0 else COLORS["fill"]
        draw.rectangle([x0, y, x0 + sum(col_widths), y + 56], fill=rgb(fill), outline=rgb(COLORS["grid"]))
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
        draw.text((46, yy - 12), f"{val:.2f}", fill=rgb(COLORS["muted"]), font=font(15))
    for i in range(5):
        xx = left + i * (right - left) / 4
        val = xmin + i * (xmax - xmin) / 4
        draw.text((xx - 18, bottom + 20), f"{val:.1f}", fill=rgb(COLORS["muted"]), font=font(15))
    draw.text((left, bottom + 58), "porosity e0", fill=rgb(COLORS["muted"]), font=font(17, True))
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


def heatmap(path: Path, title: str, subtitle: str, data: pd.DataFrame, value_col: str, fmt: str) -> None:
    img, draw = canvas(title, subtitle, (1500, 780))
    left, top = 190, 150
    cw, ch = 150, 78
    rows = sorted(data["e0"].unique())
    cols = POROSITY_MODES
    vals = data[value_col].dropna()
    vmin, vmax = float(vals.min()), float(vals.max())
    if vmin == vmax:
        vmax = vmin + 1
    draw.text((left - 95, top + 20), "e0", fill=rgb(COLORS["muted"]), font=font(18, True))
    for ci, col in enumerate(cols):
        draw.rectangle([left + ci * cw, top, left + (ci + 1) * cw, top + ch], fill=rgb("#E6ECF3"), outline=rgb(COLORS["grid"]))
        draw.text((left + ci * cw + 20, top + 26), col, fill=rgb(COLORS["navy"]), font=font(17, True))
    for ri, e0 in enumerate(rows):
        y = top + (ri + 1) * ch
        draw.text((left - 80, y + 26), f"{e0:.1f}", fill=rgb(COLORS["muted"]), font=font(17, True))
        for ci, col in enumerate(cols):
            item = data[(data["e0"] == e0) & (data["porosity_name"] == col)]
            value = float(item[value_col].iloc[0]) if not item.empty else float("nan")
            if pd.isna(value):
                fill = "#F3F4F6"
                label = "NA"
            else:
                t = (value - vmin) / (vmax - vmin)
                r = int(230 - 110 * t)
                g = int(242 - 115 * t)
                b = int(255 - 45 * t)
                fill = f"#{r:02X}{g:02X}{b:02X}"
                label = fmt.format(value)
            draw.rectangle([left + ci * cw, y, left + (ci + 1) * cw, y + ch], fill=rgb(fill), outline=rgb(COLORS["grid"]))
            tw, _ = text_size(draw, label, font(17, True))
            draw.text((left + ci * cw + (cw - tw) / 2, y + 27), label, fill=rgb(COLORS["ink"]), font=font(17, True))
    footer(draw, img.size)
    img.save(path)


def load_data() -> pd.DataFrame:
    if not INPUT.exists():
        raise FileNotFoundError(f"Missing {INPUT}")
    df = pd.read_csv(INPUT)
    for col in ["vf0", "e0", "porosity_mode", "w_center_mm", "theta_span_K", "magnetoelectric_efficiency"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")
    df["w_abs_mm"] = df["w_center_mm"].abs()
    return df


def add_baseline_ratios(df: pd.DataFrame) -> pd.DataFrame:
    base = df[df["e0"].eq(0) & df["porosity_name"].eq("Even")][
        ["fg_mode", "vf0", "load_case", "w_abs_mm", "theta_span_K", "magnetoelectric_efficiency"]
    ].rename(
        columns={
            "w_abs_mm": "w_abs_baseline_mm",
            "theta_span_K": "theta_span_baseline_K",
            "magnetoelectric_efficiency": "me_eff_baseline",
        }
    )
    out = df.merge(base, on=["fg_mode", "vf0", "load_case"], how="left")
    out["w_abs_ratio"] = out["w_abs_mm"] / out["w_abs_baseline_mm"]
    out["theta_span_ratio"] = out["theta_span_K"] / out["theta_span_baseline_K"]
    out["me_eff_ratio"] = out["magnetoelectric_efficiency"] / out["me_eff_baseline"]
    return out


def mean_series(df: pd.DataFrame, load_case: str, metric: str, fg_mode: str) -> dict[str, pd.DataFrame]:
    subset = df[(df["load_case"] == load_case) & (df["fg_mode"] == fg_mode)]
    rows = []
    for poro in POROSITY_MODES:
        part = subset[(subset["porosity_name"] == poro) | (subset["e0"] == 0)]
        grp = part.groupby("e0", as_index=False)[metric].mean().sort_values("e0")
        grp["porosity_name"] = poro
        rows.append((poro, grp))
    return dict(rows)


def build() -> None:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    df = add_baseline_ratios(load_data())
    if len(df) != EXPECTED_ROWS:
        raise SystemExit(f"Expected {EXPECTED_ROWS} rows, got {len(df)}")
    failed = df[df["status"] != "ok"]
    if not failed.empty:
        raise SystemExit(f"{len(failed)} rows failed; inspect results_static_porous.csv")

    copy2(INPUT, DATA_DIR / INPUT.name)
    df.to_csv(DATA_DIR / "results_static_porous_with_baseline_ratios.csv", index=False)
    summary = df.groupby(["load_case", "fg_mode", "porosity_name", "e0"], as_index=False).agg(
        w_abs_mean_mm=("w_abs_mm", "mean"),
        w_abs_ratio_mean=("w_abs_ratio", "mean"),
        theta_span_mean_K=("theta_span_K", "mean"),
        theta_span_ratio_mean=("theta_span_ratio", "mean"),
        me_eff_mean=("magnetoelectric_efficiency", "mean"),
        me_eff_ratio_mean=("me_eff_ratio", "mean"),
    )
    summary.to_csv(DATA_DIR / "porous_static_summary_by_group.csv", index=False)

    coverage_rows = []
    for load in LOAD_CASES:
        part = df[df["load_case"] == load]
        coverage_rows.append([load, len(part), part["fg_mode"].nunique(), part["vf0"].nunique(), part["e0"].nunique(), part["status"].eq("ok").sum()])
    table_image(
        FIG_DIR / "01_porous_coverage_table.png",
        "含孔隙 30x30 静力扫描覆盖情况",
        ["载荷", "行数", "FG数", "Vf数", "e0数", "ok"],
        coverage_rows,
        [160, 140, 140, 140, 140, 140],
        "2 FG × 130 porous cases × 3 load cases = 390 rows",
    )

    for fg in FG_MODES:
        line_chart(
            FIG_DIR / f"02_{fg}_elastic_deflection_ratio_vs_e0.png",
            f"{fg} 分布：孔隙率对机械挠度放大倍率的影响",
            "Case A，按 Vf0=0.1/0.3/0.5/0.7/0.9 平均，相对 e0=0 基线归一化",
            mean_series(df, "elastic", "w_abs_ratio", fg),
            "e0",
            "w_abs_ratio",
            "|w| / |w| baseline",
        )
        line_chart(
            FIG_DIR / f"03_{fg}_theta_ratio_vs_e0.png",
            f"{fg} 分布：孔隙率对层温差跨度的影响",
            "Case A，按 Vf0 平均，相对 e0=0 基线归一化",
            mean_series(df, "elastic", "theta_span_ratio", fg),
            "e0",
            "theta_span_ratio",
            "theta span ratio",
        )
        line_chart(
            FIG_DIR / f"04_{fg}_me_efficiency_vs_e0.png",
            f"{fg} 分布：孔隙率对磁电效率的影响",
            "Case C，按 Vf0 平均",
            mean_series(df, "magneto", "magnetoelectric_efficiency", fg),
            "e0",
            "magnetoelectric_efficiency",
            "ME efficiency",
        )

    for fg in FG_MODES:
        hdata = summary[(summary["load_case"] == "elastic") & (summary["fg_mode"] == fg) & (summary["e0"] > 0)]
        heatmap(
            FIG_DIR / f"05_{fg}_deflection_ratio_heatmap.png",
            f"{fg} 分布：机械挠度放大倍率热图",
            "Case A，按 Vf0 平均，数值为 |w| / e0=0 基线",
            hdata.rename(columns={"w_abs_ratio_mean": "value"}),
            "value",
            "{:.2f}",
        )

    rank = summary[(summary["load_case"] == "elastic") & (summary["e0"] > 0)]
    rank = rank.sort_values("w_abs_ratio_mean", ascending=False).head(10)
    rank_rows = [
        [r.fg_mode, r.porosity_name, f"{r.e0:.1f}", f"{r.w_abs_ratio_mean:.3f}", f"{r.theta_span_ratio_mean:.3f}"]
        for r in rank.itertuples(index=False)
    ]
    table_image(
        FIG_DIR / "06_top_deflection_amplification_table.png",
        "孔隙导致的最大机械挠度放大组合",
        ["FG", "孔隙模式", "e0", "|w|倍率", "θ倍率"],
        rank_rows,
        [120, 200, 100, 160, 160],
        "Case A，按 5 个 Vf0 平均后排序",
    )

    key = summary[(summary["load_case"] == "elastic") & (summary["e0"] > 0)]
    worst = key.loc[key["w_abs_ratio_mean"].idxmax()]
    mild = key.loc[key["w_abs_ratio_mean"].idxmin()]
    me = summary[(summary["load_case"] == "magneto") & (summary["e0"] > 0)]
    me_best = me.loc[me["me_eff_mean"].idxmax()]
    me_worst = me.loc[me["me_eff_mean"].idxmin()]

    README.write_text(
        f"""# 含孔隙 FG-MEE 30x30 静力扫描（2026-05-28）

本报告基于 `output/results_static_porous.csv`，覆盖 U/X 两种 FG 分布、5 个体积分数、5 个孔隙率水平和 3 种孔隙分布模式。`e0=0` 时三种孔隙模式等价，因此只保留 Even 基线；共 130 个输入算例、390 行三载荷结果。

## 1. 数据质量

| 项目 | 数值 |
| --- | ---: |
| 总结果行数 | {len(df)} |
| 成功行数 | {df['status'].eq('ok').sum()} |
| FG 分布 | {df['fg_mode'].nunique()} |
| 体积分数水平 | {df['vf0'].nunique()} |
| 孔隙率水平 | {df['e0'].nunique()} |

![覆盖情况](figures/01_porous_coverage_table.png)

## 2. 主要规律

- 机械挠度放大最强的平均组合是 {worst.fg_mode}-{worst.porosity_name}-e0={worst.e0:.1f}，相对无孔隙基线放大 {worst.w_abs_ratio_mean:.3f} 倍。
- 机械挠度放大最弱的平均组合是 {mild.fg_mode}-{mild.porosity_name}-e0={mild.e0:.1f}，相对基线为 {mild.w_abs_ratio_mean:.3f} 倍。
- 磁电效率最高的平均组合是 {me_best.fg_mode}-{me_best.porosity_name}-e0={me_best.e0:.1f}，平均效率 {me_best.me_eff_mean:.4f}。
- 磁电效率最低的平均组合是 {me_worst.fg_mode}-{me_worst.porosity_name}-e0={me_worst.e0:.1f}，平均效率 {me_worst.me_eff_mean:.4f}。

## 3. 图表索引

![U挠度倍率](figures/02_U_elastic_deflection_ratio_vs_e0.png)

![X挠度倍率](figures/02_X_elastic_deflection_ratio_vs_e0.png)

![U温差倍率](figures/03_U_theta_ratio_vs_e0.png)

![X温差倍率](figures/03_X_theta_ratio_vs_e0.png)

![U磁电效率](figures/04_U_me_efficiency_vs_e0.png)

![X磁电效率](figures/04_X_me_efficiency_vs_e0.png)

![U热图](figures/05_U_deflection_ratio_heatmap.png)

![X热图](figures/05_X_deflection_ratio_heatmap.png)

![排序表](figures/06_top_deflection_amplification_table.png)

## 4. 文件索引

| 文件 | 用途 |
| --- | --- |
| `data/results_static_porous.csv` | 原始 390 行结果 |
| `data/results_static_porous_with_baseline_ratios.csv` | 增加相对 e0=0 基线倍率 |
| `data/porous_static_summary_by_group.csv` | 按载荷/FG/孔隙模式/e0 汇总 |
| `figures/*.png` | 可直接截入论文或汇报 |
""",
        encoding="utf-8",
    )
    print(f"Wrote {README}")
    print(f"Wrote figures to {FIG_DIR}")


if __name__ == "__main__":
    build()
