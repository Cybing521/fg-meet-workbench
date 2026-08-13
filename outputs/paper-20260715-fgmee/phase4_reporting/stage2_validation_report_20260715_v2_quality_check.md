# Stage 2 v2 LaTeX/PDF 质量检查

检查日期：2026-07-15

## 内容核验

- 20×20 正向电/磁位移、绝对差和相对差已与正式 MATLAB/COMSOL CSV 逐项核对。
- MATLAB 10/20/30、COMSOL 面内 15/20 及每层厚度 1/5/10 的网格变化已与 `error_source_matrix.csv` 核对。
- 场强、域应力/修正侧压力、三种三维材料补全和中心线统一尺度诊断均已写入报告。
- 报告明确把 9%–11% 冻结为“非同构模型形式差”，未写成 20×20 网格故障，也未用经验系数追平。
- 热释电/热释磁装配系数的精确 10 倍证据已与 `inverse_pyro_overcount_audit.csv` 核对。
- 0.5/1/2 mm 修正版 MATLAB 与 10/15/20 COMSOL 对比已与 `inverse_sensor_corrected_comparison.csv` 核对。
- 报告明确标注反向 COMSOL 为 B 级三维力学—冻结本构后处理，不是完全独立电磁 PDE。
- 曲率—梯度 30 行筛选、R=0.4 m 半径审计、20/30 网格变化和交互/网格比已与三份最终 CSV 核对。
- 压力交互未分辨、电/磁交互已分辨的边界已分别报告。
- 实验矩阵与 `stage2_experiment_result.md` 已同步为修正后的当前状态。

## 编译与逐页视觉核验

- 使用便携 Tectonic 0.16.9 成功编译。
- PDF 为 A4、9 页、未加密，文件大小 224,280 bytes。
- 使用 Poppler 以 140 dpi 将 9 页全部渲染为 PNG，并逐页目视检查。
- 标题页、目录、8 个表、2 幅图、状态颜色、长路径索引、页眉页脚均正常。
- 未发现裁切、文字/图形重叠、黑块、缺字或跨页表格错误。
- 编译日志无 `Overfull`、`Underfull`、`Missing character` 或致命错误。
- 日志仅含 Windows 字体绝对路径、CJK 字体族重定义和 PDF 书签数学符号提示；不影响当前视觉结果。

## 文件与哈希

- LaTeX：`outputs/paper-20260715-fgmee/phase4_reporting/stage2_validation_report_20260715_v2.tex`
  - SHA-256：`D6BFAA1C19A5DC84D6D832254B96C1E23493E87ABFA0498F2D24E91DE204282C`
- PDF：`output/pdf/stage2_validation_report_20260715_v2.pdf`
  - SHA-256：`3CF3CC477985A4CFF2011480E7A2C2383B341C4BE6C3CEC2437C57E8E84718CF`
- 图 1 PDF：`3CFC26B0DAF9B5355E209879F42161F47B5DB25F40BE51854B156C655C8DDE5D`
- 图 2 PDF：`0A0359C91EE499A8DC6ED5C01AC87D8D88078CA116C8275D09B516645A9BC1B1`

## 当前交付判定

新版 LaTeX、数值内容、图表、PDF 编译和逐页视觉验收均通过。科学边界仍按报告第 5 节执行：非同构正向对比不能宣称已通过 1%，全半径高精度复算和代表曲壳独立模型仍属于投稿前必要工作。
