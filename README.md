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

### 4. COMSOL 对照（同一 `caseFile`）

```bash
python3 tools/export_comsol_layers.py cases/Thermal_CFFF_X_Vf0.5-30x30-10layer.txt
```

在 COMSOL 中按 `comsol/export/*_layers.csv` 赋 10 层材料，边界 CFFF，载荷见 `comsol/docs/equivalent-loads.md`，结果填入 `comsol/results/validation_log_template.csv`。

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
