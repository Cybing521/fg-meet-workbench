# fg-meet-workbench

功能梯度磁-电-弹性（FG-MEE）板在 **热-磁-电-弹性全耦合** 下的参数化仿真工作区：在钱沈云热耦合 MEET 程序上，叠加赵亚飞式 FG 分层材料输入（体积分数 × 分布模式交叉组合）。

**注意：上游 MEET 源码为课题组私有材料，本仓库仅包含工作流脚本与试点输入文件，不包含完整 MEET 求解器。**

---

## 仓库内容

| 目录/文件 | 说明 |
|-----------|------|
| `materials/` | BaTiO3/CoFe2O4 混合律、FG 分布 U/V/X/O/P |
| `tools/generate_cases.py` | 批量生成 MEET 输入文件（无需 MATLAB） |
| `tools/*.m` | MATERIAL 段替换、与参考文件对比 |
| `templates/` | 30×30×10 方板 CFFF 网格模板 |
| `cases/` | 已生成的试点 InputFile + `pilot_cases.csv` |
| `run_phase1_static_elastic.m` | 单工况静力（力载荷） |
| `TODO.md` | 分阶段任务清单 |

---

## 新电脑配置（换机跑结果）

### 1. 克隆本仓库

```bash
git clone <你的仓库地址> fg-meet-workbench
cd fg-meet-workbench
```

### 2. 拷贝私有 MEET 程序（勿提交到 Git）

在 `fg-meet-workbench` 的**上一级目录**放置（推荐文件夹名）：

```
your-workdir/
├── fg-meet-workbench/          # 本仓库
├── meet-elastic-thermal/       # 来自：钱沈云/双向耦合程序-new/.../MEET-elastic-thermal
├── meet-electro-thermal/       # 可选，电-热工况
├── meet-magneto-thermal/       # 可选，磁-热工况
└── meet-subfun/                # 来自：.../SubFunMFC
```

源路径（原整合包内）：

- `整合/钱沈云论文及相关代码/双向耦合程序-new/双向耦合程序-new/MEET-elastic-thermal`
- `整合/钱沈云论文及相关代码/双向耦合程序-new/双向耦合程序-new/SubFunMFC`

### 3. 配置本机路径

```bash
cp config_paths_local.example.m config_paths_local.m
```

编辑 `config_paths_local.m` 中的目录（若未使用推荐布局，改成绝对路径即可）。

### 4. Python（生成输入文件，可选）

```bash
python3 tools/generate_cases.py
```

会刷新 `cases/*.txt` 并校验 `U + Vf0=0.6` 与钱沈云参考材料一致。

### 5. MATLAB（跑有限元）

```matlab
cd('path/to/fg-meet-workbench');
paths = setup_paths;          % 自动加载 config_paths_local.m（若存在）

% 生成/刷新试点输入（也可用 Python 已完成）
% run('run_phase1_generate_cases.m');

% 单工况静力：CFFF，15000 Pa，U型 Vf0=0.6
run('run_phase1_static_elastic.m');
```

结果保存在 `output/phase1_static_U_Vf06.mat`。

### 6. 指定其他工况

修改 `run_phase1_static_elastic.m` 中的：

```matlab
caseFile = fullfile(paths.cases, 'Thermal_CFFF_X_Vf0.5-30x30-10layer.txt');
```

或在 MEET 目录中手动指定 `InputFile` 为 `cases/` 下任意文件。

---

## 设计参数（任务书）

| 参数 | 取值 |
|------|------|
| 体积分数 Vf0 | 0.1–0.9（BaTiO3:CoFe2O4 = 1:9 … 9:1） |
| FG 分布 | U 均匀、V 线性、X 表面富集、O 中心富集、P 幂律 |
| Case A | 均布压力 15000 Pa |
| Case B | 上下表面 ±300 V |
| Case C | 上下表面 ±200 A 磁势 |
| 边界 | 主算例 CFFF |

---

## 试点工况（已入库）

见 `cases/pilot_cases.csv`：U/X/V × Vf0.3/0.5/0.7，以及基准 `Thermal_CFFF_U_Vf0.6-30x30-10layer.txt`。

---

## 开发说明

- 材料行字段与 `Thermal_CFFFplate_0.6Vf-30x30-10layer.txt` 一致（27 列）；`A1/A2` 为热应力模量 λ，非热膨胀系数 α。
- 完整 5×9 组合与批量后处理见 [TODO.md](TODO.md) 阶段 2。

---

## 许可证与保密

课题组内部使用。不得将钱沈云/赵亚飞原始程序上传至公开仓库。
