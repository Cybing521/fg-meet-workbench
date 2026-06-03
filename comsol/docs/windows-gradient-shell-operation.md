# Windows 操作路线：梯度板壳示意图与 COMSOL 验证

本文档给出两件事的实际操作路线：一是把“材料分布梯度板壳”示意图放入报告，二是在 Windows + COMSOL 上继续做结果正确性验证。

## 1. 已准备好的示意图

| 用途 | 文件 |
|------|------|
| 报告插图 PNG | `paper/figures/fg_gradient_shell_schematic.png` |
| 可编辑矢量 SVG | `paper/figures/fg_gradient_shell_schematic.svg` |
| 生成脚本 | `tools/make_fg_shell_schematic.py` |

图中左侧表示 10 层板壳分域：每一层取层中面体积分数，换算成一组等效材料常数。右上显示 U/V/X/O/P 五种材料体积分数曲线，右下显示 Even、Uneven、LogUneven 三种孔隙退化模式。

如果在 WPS/Word 中手工排版，把 PNG 插到“功能梯度材料分布”小节之后即可。推荐图题：

> 功能梯度材料分布与含孔隙板壳分层模型示意图

## 2. Windows 环境准备

1. 打开 PowerShell 或 Git Bash。
2. 进入仓库目录。

```powershell
cd D:\path\to\fg-meet-workbench
```

3. 确认当前代码干净或只包含自己准备提交的改动。

```powershell
git status
```

4. 如需重新生成示意图，执行：

```powershell
python tools\make_fg_shell_schematic.py
```

5. 如需重新编译中文报告，执行：

```powershell
cd paper
xelatex main_zh.tex
xelatex main_zh.tex
cd ..
```

## 3. 结果正确性的验证路线

2 mm 耦合转化表属于 MATLAB 模型内部的正向驱动与反向传感一致性检查，能说明耦合方程实现自洽，但不能单独作为外部正确性证据。外部验证按下列优先级补足：

| 优先级 | 验证方式 | 操作内容 | 记录位置 |
|--------|----------|----------|----------|
| 1 | 已发表模型/基准结果对照 | 若找到完全同几何、同材料、同边界、同载荷的文献表格，直接列 MATLAB 与文献误差 | `paper/main_zh.tex` 第 4 章 |
| 2 | COMSOL 独立建模验证 | 无完全一致文献时，使用 COMSOL 10 层实体模型复现代表工况 | `comsol/results/validation_log.csv` |
| 3 | 网格与分层敏感性 | 若误差超过 5%，先查 swept 网格、每层扫掠单元数、载荷面积和边界选择 | `comsol/results/validation_experiments_*.csv` |

当前仓库已经完成 U / Vf0=0.6 / CFFF / Case A 的 COMSOL 对照，中心点误差 3.77%，15 点最大误差 4.93%。后续 Windows 侧重点是补非 U、CFCF 和含孔隙代表工况。

## 4. COMSOL GUI 具体操作

### 4.1 从已验证模型复制新算例

1. 打开已经通过验证的 U / Vf0=0.6 / CFFF 基准 COMSOL 模型。
2. 另存为新文件，文件名建议包含目标工况，例如：
   - `FG_V_Vf06_CFFF_validation.mph`
   - `FG_X_Vf01_CFCF_validation.mph`
   - `Porous_U_Vf05_e20_Even_CFFF_validation.mph`
3. 保留几何、10 层实体域、swept quad/hex 网格、mesh size 4、每层 7 个扫掠单元。

### 4.2 导入或手工填写 10 层材料参数

按 `comsol/results/manual_validation_plan.csv` 选择目标工况对应的 CSV。

| 目标 | CSV |
|------|-----|
| V / Vf0=0.6 / CFFF | `comsol/export/nonU/FG_V_Vf0.6_layers.csv` |
| X / Vf0=0.6 / CFFF | `comsol/export/nonU/FG_X_Vf0.6_layers.csv` |
| X / Vf0=0.1 / CFCF | `comsol/export/Thermal_CFCF_X_Vf0.1-30x30-10layer_layers.csv` |
| U / Vf0=0.5 / e0=0.2 / Even / CFFF | `comsol/export/porous/Porous_U_Vf0.5_e20_Even_layers.csv` |
| U / Vf0=0.5 / e0=0.3 / Even / CFFF | `comsol/export/porous/Porous_U_Vf0.5_e30_Even_layers.csv` |
| X / Vf0=0.5 / e0=0.2 / Even / CFFF | `comsol/export/porous/Porous_X_Vf0.5_e20_Even_layers.csv` |

逐层对应关系固定为：CSV 第 1 行对应底部第 1 层，CSV 第 10 行对应顶部第 10 层。需要映射的字段包括：

`E1`, `E2`, `v12`, `v23`, `G12`, `G13`, `G23`, `d31`, `d32`, `q31`, `q32`, `g33`, `k33`, `r33`, `A1`, `A2`, `PyroE`, `PyroM`, `Cv`, `HC`, `Density`。

### 4.3 边界和载荷

1. CFFF 工况保持一边固支、三边自由。
2. CFCF 工况改成两对边固支，不能只替换材料 CSV。
3. Case A 机械载荷取顶面压力 `15000 Pa`。
4. 载荷方向和已有基准模型保持一致。

### 4.4 求解与取点

1. 运行 Stationary study。
2. 在 `comsol/data/validation_points.csv` 中 15 个坐标处提取 z 位移。
3. 单位统一为 mm。
4. 与 `manual_validation_plan.csv` 对应的 MATLAB 中心挠度，以及 15 点 MATLAB 结果进行对比。
5. 把结果追加到 `comsol/results/validation_log.csv`。若是新表，先复制 `comsol/results/validation_log_template.csv`。

## 5. 通过标准

| 指标 | 标准 |
|------|------|
| 中心点相对误差 | < 5% |
| 15 点最大相对误差 | < 5%，或对受约束边附近插值误差做出说明 |
| 记录完整性 | 必须写明 mesh mode、mesh size、每层扫掠单元数、CSV 路径、边界条件和载荷方向 |

若误差超过 5%，优先检查三项：边界选择、顶面压力方向、每层扫掠单元数。不要先改 MATLAB 数据。
