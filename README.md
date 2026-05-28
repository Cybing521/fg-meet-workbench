# fg-meet-workbench

功能梯度磁-电-弹性（FG-MEE）板在 **热-磁-电-弹性全耦合** 下的参数化仿真一体化仓库：含 **MATLAB 板壳有限元主程序**、**FG 输入生成工具**、**COMSOL 验证流程**。

---

## 仓库结构

```
fg-meet-workbench/
├── matlab/
│   ├── meet-fem-core/           # 八节点板壳 MEET 有限元核心（单元、材料、求解器）
│   ├── meet-elastic-thermal/    # Case A：力-热耦合
│   ├── meet-electro-thermal/    # Case B：电-热耦合
│   ├── meet-magneto-thermal/    # Case C：磁-热耦合
│   └── run_meet_static.m        # 统一静力入口
├── comsol/                      # COMSOL 对照验证（文档、选点、结果表模板）
├── materials/                   # FG 分布 + BaTiO3/CoFe2O4 混合律
├── tools/                       # Python/MATLAB 输入生成与 COMSOL 导出
├── cases/                       # 生成的 MEET 输入文件（试点 + 可扩展全组合）
├── templates/                   # 30×30×10 方板 CFFF 网格模板
├── reference/                   # 历史 FG-MEEP 输入样例（格式对照）
├── output/                      # 运行结果（gitignore）
├── setup_paths.m
├── run_phase1_static_elastic.m  # 阶段 1 冒烟测试
└── TODO.md
```

---

## MATLAB 做什么

| 职责 | 说明 |
|------|------|
| **主求解** | 全耦合静力/动力：位移 + 变形诱导厚度温差 θ |
| **参数扫描** | 体积分数 × FG 分布 × 三种载荷（力/电/磁） |
| **入口** | `run_meet_static(caseFile, 'elastic' \| 'electro' \| 'magneto')` |

**载荷对应：**

| loadCase | 物理 | 典型设置 |
|----------|------|----------|
| `elastic` | Case A | 上表面 15000 Pa |
| `electro` | Case B | 上下 ±300 V |
| `magneto` | Case C | 上下 ±200 A 磁势 |

---

## COMSOL 做什么

| 职责 | 说明 |
|------|------|
| **验证** | 代表性工况独立建模，与 MATLAB 对比 |
| **不做** | 全参数 45×3 批量主算例（太慢） |
| **方法** | 分层固体 + 压电模块等效全耦合（见 `comsol/docs/`） |
| **导出** | `python3 tools/export_comsol_layers.py cases/xxx.txt` → 分层 CSV |
| **当前基准** | 已跑通 U / Vf0.6 / CFFF / Case A 的 COMSOL CLI 15 点弹性对照 |

详见 [comsol/README.md](comsol/README.md)。

---

## 快速开始

### 1. 克隆

```bash
git clone git@github.com:Cybing521/fg-meet-workbench.git
cd fg-meet-workbench
```

### 2. 生成/刷新输入文件（无需 MATLAB）

```bash
python3 tools/generate_cases.py
```

这会生成完整主算例清单 `cases/manifest_full.csv`（5 种 FG × 9 个 Vf0）和阶段 1 试点清单 `cases/pilot_cases.csv`。

### 3. MATLAB 单工况

```matlab
cd('path/to/fg-meet-workbench');
setup_paths;
run('run_phase1_static_elastic.m');
```

或：

```matlab
paths = setup_paths;
caseFile = fullfile(paths.cases, 'Thermal_CFFF_X_Vf0.5-30x30-10layer.txt');
run_meet_static(caseFile, 'elastic', 'OutTag', 'X_Vf05');
```

### 4. MATLAB 全批量静力主算例

```matlab
cd('path/to/fg-meet-workbench');
setup_paths;
run('run_batch_static.m');
```

结果写入 `output/results_static.csv`，包含 Case A/B/C 的中心挠度、层平均温差和磁电效率指标。脚本会跳过已成功完成的 `case_id`，中断后可直接重跑续算。

`run_meet_static.m` 会按节点约束标志把求解后的 reduced `Qd` 还原成完整节点自由度 `TQd`，再提取中心挠度；若更新过该逻辑，需要重跑批量表以刷新 `w_center_mm`。

### 5. MATLAB 2 mm 转化验证

```matlab
cd('path/to/fg-meet-workbench');
setup_paths;
run('run_coupling_validation_2mm.m');
```

默认使用 `cases/Thermal_CFFF_U_Vf0.6-30x30-10layer.txt`，以中心挠度绝对值 2 mm 为参考，验证：

- 电势/磁势正向转化为挠度；
- 2 mm 挠度反向诱导出的电势/磁势；
- 按沈的回代方式，由耦合矩阵直接计算磁势→位移→感生电势、电势→位移→感生磁势，并给出转化系数。

结果写入 `output/coupling_validation_2mm.csv` 和 `output/coupling_validation_2mm.mat`。可用环境变量覆盖输入与阈值，例如 `FG_VALIDATE_CASE`、`FG_VALIDATE_TARGET_MM`、`FG_VALIDATE_REL_TOL`。

### 6. COMSOL 对照（同一 `caseFile`）

```bash
python3 tools/export_comsol_layers.py cases/Thermal_CFFF_X_Vf0.5-30x30-10layer.txt
```

在 COMSOL 中按 `comsol/export/*_layers.csv` 赋 10 层材料，边界 CFFF，载荷见 `comsol/docs/equivalent-loads.md`，结果填入 `comsol/results/validation_log_template.csv`。

已自动化的弹性基准算例：

```powershell
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolcompile.exe' tools\comsol\RunElasticCfffValidation.java
$env:FG_COMSOL_LOAD_MODE='forcearea'
$env:FG_COMSOL_MESH_MODE='sweep'
$env:FG_COMSOL_MESH_SIZE='4'
$env:FG_COMSOL_SWEEP_LAYERS='7'
$env:FG_COMSOL_LAYERED='true'
$env:FG_COMSOL_LAYER_CSV='G:\fg-meet-workbench\comsol\export\Thermal_CFFF_U_Vf0.6-30x30-10layer_layers.csv'
$env:FG_COMSOL_RUN_TAG='layered_csv_sweep7_mesh4'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' -inputfile tools\comsol\RunElasticCfffValidation.class -outputfile output\comsol_elastic_cfff_U_Vf06_layered_csv_sweep7_mesh4.mph -batchlog output\comsol_elastic_cfff_U_Vf06_layered_csv_sweep7_mesh4.log
python tools\compare_comsol_meet_validation.py --comsol-csv output\comsol_elastic_cfff_U_Vf06_layered_csv_sweep7_mesh4_points.csv --comsol-mesh "3D solid 10-domain CSV materials, swept quad/hex mesh, hauto size 4, 7 elements per material layer, force area"
```

输出 `output/comsol_elastic_cfff_U_Vf06_layered_csv_sweep7_mesh4_points.csv`、`comsol/results/validation_points_U_Vf06_elastic.csv` 和 `comsol/results/validation_log.csv`。当前通过基准：中心点 p8 为 MATLAB -2.12752 mm、COMSOL -2.20774 mm，相对误差 3.77%；15 点最大相对误差 4.927%，平均 3.51%。

---

## 动力代表算例

已新增 `run_dynamic_representative.m` 作为 Newmark 动力入口。当前完成的是可快速复现的 10x10 pilot：

```powershell
$env:FG_DYNAMIC_TTOTAL='0.04'
$env:FG_DYNAMIC_DT='0.0001'
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_dynamic_representative"
```

输出 `output/dynamic_U_Vf06_elastic_10x10_timeseries.csv`、`output/dynamic_U_Vf06_elastic_10x10_summary.csv`，并整理为 `reports/2026-05-22-dynamic/README.md`。当前结果：静态中心挠度 -2.1284 mm，动力峰值 -4.4995 mm，峰值时间 28.90 ms，第一阶频率 52.20 Hz。

30x30 直接 Newmark 冒烟测试超过 5 min，已新增 `run_dynamic_modal_30x30.m` 改用模态降阶：

```powershell
$env:FG_MODAL_NMODES='8'
$env:FG_MODAL_TTOTAL='0.04'
$env:FG_MODAL_DT='0.0001'
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_dynamic_modal_30x30"
```

30x30 模态输出 `output/dynamic_modal_30x30_U_Vf06_elastic_8modes_*.csv`，并整理为 `reports/2026-05-22-modal30x30/README.md`。当前结果：8 阶模态静态捕获比例 1.00037，耦合静态中心挠度 -2.1275 mm，机械静态中心挠度 -2.2947 mm，动力峰值 -4.4279 mm，峰值时间 9.50 ms，第一阶频率 52.20 Hz。

已补充 30x30 模态阶数敏感性，采用一次装配、一次求前 16 阶，再分别保留 4/6/8/12/16 阶恢复时程：

```powershell
$env:FG_MODAL_SENS_MODES='4,6,8,12,16'
$env:FG_MODAL_SENS_TTOTAL='0.04'
$env:FG_MODAL_SENS_DT='0.0001'
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_dynamic_modal_sensitivity_30x30"
python tools\build_modal_sensitivity_report.py
```

敏感性输出 `output/dynamic_modal_30x30_U_Vf06_elastic_sensitivity_*.csv`，并整理为 `reports/2026-05-22-modal-sensitivity/README.md`。当前 16 阶结果：静态捕获比例 0.999965，动力峰值 -4.4270 mm，峰值时间 9.60 ms，最大层温差跨度 5.0363 K。与 8 阶相比，峰值绝对值差约 0.0009 mm、最大温差跨度差约 0.0035 K，说明 8 阶结果已基本收敛，汇报中可把 16 阶作为更稳妥口径。

已继续补充 30x30 16 阶模态阻尼敏感性，固定 16 阶并比较 0/0.5/0.8/1.5% 阻尼：

```powershell
$env:FG_MODAL_SENS_MODES='16'
$env:FG_MODAL_SENS_DAMPING_LIST='0,0.005,0.008,0.015'
$env:FG_MODAL_SENS_TAG='dynamic_modal_30x30_U_Vf06_elastic_damping_sensitivity'
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_dynamic_modal_sensitivity_30x30"
python tools\build_modal_damping_report.py
```

阻尼敏感性输出 `reports/2026-05-23-modal-damping/README.md`。当前结果：无阻尼峰值 -4.5039 mm，0.8% 默认口径峰值 -4.4270 mm，1.5% 阻尼峰值 -4.3858 mm；可用于说明动力峰值范围和默认阻尼口径。

已补充 10x10 完整 Newmark FG 分布扫描，固定 Vf0=0.6、CFFF、Case A、40 ms、dt=0.1 ms，比较 U/V/X/O/P 五种分布：

```powershell
python tools\generate_dynamic_10x10_cases.py
$modes = @('U','V','X','O','P')
foreach ($mode in $modes) {
    $env:FG_DYNAMIC_CASE_FILE = "cases\dynamic_10x10\Thermal_CFFF_${mode}_Vf0.6-10x10-10layer.txt"
    $env:FG_DYNAMIC_TAG = "dynamic_10x10_${mode}_Vf06_elastic_fgsweep"
    $env:FG_DYNAMIC_TTOTAL = '0.04'
    $env:FG_DYNAMIC_DT = '0.0001'
    & 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_dynamic_representative"
}
python tools\build_dynamic_fg_sweep_report.py
```

FG 分布扫描输出 `reports/2026-05-27-dynamic-fg-sweep/README.md`。当前结果：峰值绝对值最小的是 P（3.2158 mm），最大的是 O（5.5157 mm）；P 的一阶频率最高 62.93 Hz，O 最低 46.57 Hz，可作为后续 30x30 FG 分布模态实验的低成本先验。

---

## 含孔隙静力扩展

已补充版本二含孔隙 FG-MEE 静力扫描。参数空间为 U/X 两种 FG 分布、5 个体积分数、5 个孔隙率水平和 3 种孔隙分布模式；`e0=0` 时三种孔隙模式等价，因此只保留 Even 基线，共 130 个输入算例、390 行三载荷结果。

```powershell
python tools\generate_porous_cases.py
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch "run_batch_static_porous"
python tools\build_porous_static_report.py
```

结果文件为 `output/results_static_porous.csv`，报告和论文级图表整理在 `reports/2026-05-28-porous-static/README.md`。当前结论：Case A 中 U-Even-e0=0.4 的平均机械挠度放大最强，相对无孔隙基线为 1.742 倍；U-Uneven-e0=0.1 放大最弱，为 1.031 倍。LaTeX 汇报 `latex-report/main.tex` 和 `latex-report/main.pdf` 已同步加入含孔隙结果。

---

## 设计参数

| 参数 | 取值 |
|------|------|
| 体积分数 Vf0 | 0.1–0.9（BaTiO3 : CoFe2O4） |
| FG 分布 | U / V / X / O / P（幂律默认 n=2） |
| 几何 | 300×300×6 mm 方板 |
| 边界 | 主算例 CFFF |

---

## 路径覆盖（可选）

默认使用仓库内 `matlab/`。若程序放在其他位置：

```bash
cp config_paths_local.example.m config_paths_local.m
```

---

## 任务进度

见 [TODO.md](TODO.md)。

---

## 说明

- 材料行中 `A1/A2` 为热应力模量 λ，与全耦合理论一致。
- `reference/fg-meep-sample-inputs/` 仅作 FG 格式参考；热耦合主算例用 `cases/` 下 `Thermal_CFFF_*.txt`。
