#!/usr/bin/env python3
"""Build a captioned MP4 that explains the COMSOL validation workflow."""

from __future__ import annotations

import csv
import subprocess
from pathlib import Path

import pandas as pd
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "reports" / "2026-06-01-comsol-validation-video"
SLIDE_DIR = OUT_DIR / "slides"
OUT_MP4 = OUT_DIR / "comsol_validation_workflow.mp4"
FFMPEG = Path(r"D:\ffmpeg-7.0.2-full_build\bin\ffmpeg.exe")
W, H = 1920, 1080
BG = (248, 250, 252)
INK = (20, 24, 33)
MUTED = (91, 103, 120)
BLUE = (21, 96, 189)
GREEN = (31, 130, 78)
ORANGE = (194, 91, 24)
LINE = (219, 225, 233)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        Path(r"C:\Windows\Fonts\msyhbd.ttc" if bold else r"C:\Windows\Fonts\msyh.ttc"),
        Path(r"C:\Windows\Fonts\Dengb.ttf" if bold else r"C:\Windows\Fonts\Deng.ttf"),
        Path(r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf"),
    ]
    for path in candidates:
        if path.is_file():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        if not para:
            lines.append("")
            continue
        current = ""
        for ch in para:
            trial = current + ch
            if draw.textlength(trial, font=fnt) <= width:
                current = trial
            else:
                if current:
                    lines.append(current)
                current = ch
        if current:
            lines.append(current)
    return lines


def text_block(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int = 34,
               color: tuple[int, int, int] = INK, width: int = 780, line_gap: int = 10) -> int:
    x, y = xy
    fnt = font(size)
    for line in wrap(draw, text, fnt, width):
        draw.text((x, y), line, fill=color, font=fnt)
        y += size + line_gap
    return y


def header(draw: ImageDraw.ImageDraw, title: str, subtitle: str) -> None:
    draw.text((84, 62), title, fill=INK, font=font(58, bold=True))
    draw.text((88, 136), subtitle, fill=MUTED, font=font(28))
    draw.line((84, 185, W - 84, 185), fill=LINE, width=3)


def card(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], title: str,
         body: str, accent: tuple[int, int, int] = BLUE) -> None:
    x0, y0, x1, y1 = box
    draw.rounded_rectangle(box, radius=18, fill=(255, 255, 255), outline=LINE, width=2)
    draw.rectangle((x0, y0, x0 + 12, y1), fill=accent)
    draw.text((x0 + 36, y0 + 28), title, fill=INK, font=font(34, bold=True))
    text_block(draw, (x0 + 36, y0 + 84), body, size=27, color=MUTED, width=x1 - x0 - 72, line_gap=8)


def paste_fit(canvas: Image.Image, img_path: Path, box: tuple[int, int, int, int]) -> None:
    if not img_path.is_file():
        return
    img = Image.open(img_path).convert("RGB")
    x0, y0, x1, y1 = box
    bw, bh = x1 - x0, y1 - y0
    img.thumbnail((bw, bh), Image.Resampling.LANCZOS)
    x = x0 + (bw - img.width) // 2
    y = y0 + (bh - img.height) // 2
    canvas.paste(img, (x, y))


def table(draw: ImageDraw.ImageDraw, x: int, y: int, headers: list[str], rows: list[list[str]],
          widths: list[int], row_h: int = 56) -> None:
    draw.rounded_rectangle((x, y, x + sum(widths), y + row_h * (len(rows) + 1)),
                           radius=14, fill=(255, 255, 255), outline=LINE, width=2)
    cx = x
    for h, w in zip(headers, widths):
        draw.text((cx + 16, y + 14), h, fill=INK, font=font(24, bold=True))
        cx += w
    draw.line((x, y + row_h, x + sum(widths), y + row_h), fill=LINE, width=2)
    for ri, row in enumerate(rows):
        cy = y + row_h * (ri + 1)
        cx = x
        for val, w in zip(row, widths):
            draw.text((cx + 16, cy + 15), val, fill=MUTED, font=font(23))
            cx += w


def make_slide(title: str, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    header(draw, title, subtitle)
    return img, draw


def save(img: Image.Image, idx: int) -> None:
    SLIDE_DIR.mkdir(parents=True, exist_ok=True)
    img.save(SLIDE_DIR / f"slide_{idx:02d}.png", quality=95)


def build_slides() -> int:
    plan = pd.read_csv(ROOT / "comsol" / "results" / "manual_validation_plan.csv")
    idx = 1

    img, draw = make_slide("COMSOL验证建模流程录制", "FG-MEE含孔隙板 | 材料CSV到COMSOL手工验证")
    text_block(draw, (110, 260), "这版视频用于汇报：数据层已经齐备，COMSOL剩余工作是把已导出的10层材料CSV导入模型，完成少量代表工况的手工验证。", 42, INK, 1120, 16)
    card(draw, (108, 575, 580, 815), "已完成", "无孔隙CFFF静力135行\nCFCF对比30行\n含孔隙静力390行\n动力代表算例已生成", GREEN)
    card(draw, (640, 575, 1112, 815), "待录制操作", "打开基准COMSOL模型\n替换10层材料参数\n设置边界和载荷\n求解并导出15点位移", ORANGE)
    card(draw, (1172, 575, 1644, 815), "论文用途", "Section 4 验证\nSection 5 静力规律\nSection 6 动力响应\n附录/答辩过程记录", BLUE)
    save(img, idx); idx += 1

    img, draw = make_slide("数据已经可以支撑论文初稿", "主数据、边界对比、孔隙扩展和动力响应都已入库")
    rows = [
        ["无孔隙CFFF", "135行", "output/results_static.csv"],
        ["CFCF对比", "30行", "output/results_static_cfcf.csv"],
        ["含孔隙静力", "390行", "output/results_static_porous.csv"],
        ["含孔隙动力", "401步", "dynamic_porous_*_timeseries.csv"],
        ["COMSOL计划", "6目标", "manual_validation_plan.csv"],
    ]
    table(draw, 118, 250, ["数据层", "规模", "文件"], rows, [360, 180, 760], 68)
    paste_fit(img, ROOT / "reports" / "2026-06-01-cfcf-static" / "figures" / "04_X_cfcf_over_cfff_w_ratio.png", (1130, 300, 1780, 800))
    save(img, idx); idx += 1

    img, draw = make_slide("待验证COMSOL目标", "5.1、5.4、6.3都已整理成CSV-ready清单")
    rows = []
    for row in plan.itertuples():
        rows.append([
            str(row.phase),
            row.boundary,
            row.matlab_case_id.replace("_elastic", ""),
            f"{row.matlab_w_center_mm:.4f}",
        ])
    table(draw, 112, 240, ["阶段", "边界", "MATLAB工况", "w中心/mm"], rows, [160, 170, 570, 220], 60)
    card(draw, (1260, 300, 1760, 780), "录制重点", "不要只展示最终云图。\n需要录到CSV材料表如何对应到COMSOL的10个材料域，这是验证可信度的核心证据。", ORANGE)
    save(img, idx); idx += 1

    img, draw = make_slide("COMSOL模型设置", "沿用已经通过误差<5%的基准设置")
    card(draw, (120, 260, 550, 500), "几何", "300 mm x 300 mm x 6 mm 方板\n厚度方向10层", BLUE)
    card(draw, (600, 260, 1030, 500), "网格", "swept quad/hex mesh\nmesh size 4\n每层7个扫掠单元", GREEN)
    card(draw, (1080, 260, 1510, 500), "载荷", "Case A\n上表面压力15000 Pa\n提取z向位移", ORANGE)
    card(draw, (360, 610, 1560, 850), "边界", "CFFF用于5.1和6.3；CFCF用于5.4。材料CSV只负责分层材料参数，边界条件仍然需要在COMSOL选择里手动切换。", BLUE)
    save(img, idx); idx += 1

    img, draw = make_slide("材料CSV导入逻辑", "每一行对应一个厚度层，每一列对应COMSOL材料常数")
    csv_files = [
        "comsol/export/nonU/FG_V_Vf0.6_layers.csv",
        "comsol/export/nonU/FG_X_Vf0.6_layers.csv",
        "comsol/export/Thermal_CFCF_X_Vf0.1-30x30-10layer_layers.csv",
        "comsol/export/porous/Porous_U_Vf0.5_e20_Even_layers.csv",
        "comsol/export/porous/Porous_U_Vf0.5_e30_Even_layers.csv",
        "comsol/export/porous/Porous_X_Vf0.5_e20_Even_layers.csv",
    ]
    text_block(draw, (118, 250), "\n".join(csv_files), 29, INK, 980, 10)
    card(draw, (1180, 270, 1760, 760), "映射字段", "E1/E2/v/G\n压电d31/d32\n压磁q31/q32\n介电/磁导/热参数\nDensity\nzC1/zC2层边界", GREEN)
    save(img, idx); idx += 1

    img, draw = make_slide("录制时的操作顺序", "建议一镜到底，求解等待部分可以暂停或剪掉")
    steps = [
        ["1", "打开已验证U/Vf0.6/CFFF模型"],
        ["2", "展示几何、10层域、swept mesh"],
        ["3", "打开目标CSV，逐层替换材料参数"],
        ["4", "设置CFFF或CFCF边界和15000 Pa载荷"],
        ["5", "求解并展示位移云图"],
        ["6", "导出15点z位移并填写validation_log"],
    ]
    table(draw, 150, 250, ["步骤", "画面内容"], steps, [150, 1150], 72)
    save(img, idx); idx += 1

    img, draw = make_slide("结果对比口径", "与MATLAB同坐标15点位移比较，中心点是最直观指标")
    rows = [
        ["V/Vf0=0.6/CFFF", "-1.620839"],
        ["X/Vf0=0.6/CFFF", "-1.810358"],
        ["X/Vf0=0.1/CFCF", "-0.072521"],
        ["U/Vf0=0.5/e0=0.2/Even", "-2.454739"],
        ["U/Vf0=0.5/e0=0.3/Even", "-2.833957"],
        ["X/Vf0=0.5/e0=0.2/Even", "-2.165514"],
    ]
    table(draw, 140, 250, ["目标", "MATLAB中心挠度/mm"], rows, [720, 360], 62)
    card(draw, (1260, 330, 1760, 720), "通过标准", "中心点误差 < 5%\n15点最大误差 < 5%\n若边缘点异常，说明网格/插值原因", GREEN)
    save(img, idx); idx += 1

    img, draw = make_slide("录制产物怎么用", "视频、CSV、验证日志共同构成可追溯证据")
    card(draw, (120, 270, 585, 780), "视频", "说明建模过程\n展示材料CSV进入COMSOL\n保留边界/网格/载荷画面", BLUE)
    card(draw, (725, 270, 1190, 780), "验证表", "15点COMSOL位移\nMATLAB参考值\n相对误差统计\nvalidation_log.csv", GREEN)
    card(draw, (1330, 270, 1795, 780), "论文", "Section 4写验证\nSection 5/6写规律\n附录可放流程视频说明", ORANGE)
    save(img, idx); idx += 1

    img, draw = make_slide("下一步", "先录COMSOL验证，再补论文Section 4")
    text_block(draw, (150, 280), "建议优先录 U/Vf0=0.5/e0=0.2/Even 的含孔隙CFFF验证。这个工况和当前孔隙动力pilot一致，最适合串起静力、动力和COMSOL验证三条线。", 44, INK, 1200, 18)
    paste_fit(img, ROOT / "reports" / "2026-06-01-porous-dynamic" / "figures" / "02_porous_dynamic_center_timeseries.png", (980, 465, 1780, 885))
    save(img, idx); idx += 1
    return idx - 1


def build_video(slide_count: int) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    concat = OUT_DIR / "slides.txt"
    with concat.open("w", encoding="utf-8", newline="\n") as f:
        for idx in range(1, slide_count + 1):
            f.write(f"file '{(SLIDE_DIR / f'slide_{idx:02d}.png').as_posix()}'\n")
            f.write("duration 7\n")
        f.write(f"file '{(SLIDE_DIR / f'slide_{slide_count:02d}.png').as_posix()}'\n")

    cmd = [
        str(FFMPEG),
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(concat),
        "-vf",
        "fps=30,format=yuv420p",
        "-c:v",
        "libx264",
        "-preset",
        "veryfast",
        "-crf",
        "20",
        str(OUT_MP4),
    ]
    subprocess.run(cmd, check=True)


def write_script() -> None:
    script = OUT_DIR / "narration.md"
    script.write_text(
        """# COMSOL验证流程视频旁白稿

1. 本视频记录FG-MEE含孔隙板的COMSOL验证建模流程。
2. MATLAB侧数据已经完成：无孔隙CFFF、CFCF边界对比、含孔隙静力扫描和动力代表算例。
3. 剩余COMSOL验证不是重新生成数据，而是在已验证模型中替换10层材料CSV。
4. 每个CSV文件的一行对应一个厚度层，材料常数来自MATLAB输入文件。
5. 非U和含孔隙验证使用CFFF边界；CFCF验证需要在COMSOL中手动切换边界选择。
6. 求解后提取15点z向位移，与MATLAB参考值比较，目标误差小于5%。
7. 这些结果将进入论文Section 4，支撑后续静力和动力结果分析。
""",
        encoding="utf-8",
    )


def main() -> None:
    if not FFMPEG.is_file():
        raise SystemExit(f"ffmpeg not found: {FFMPEG}")
    count = build_slides()
    build_video(count)
    write_script()
    print(f"Wrote {OUT_MP4}")


if __name__ == "__main__":
    main()
