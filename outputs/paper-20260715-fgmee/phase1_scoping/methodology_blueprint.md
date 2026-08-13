# Methodology Blueprint

## Material Passport

- Origin Skill: `deep-research`
- Origin Mode: `full`
- Origin Date: `2026-07-15T10:51:58+08:00`
- Verification Status: `UNVERIFIED`
- Version Label: `research_v1`
- Upstream Dependencies: `research_question_brief_research_v1`

## Research Paradigm

**Selected**：Positivist computational mechanics。

**Justification**：研究问题关注可重复的位移、场量和误差指标，所有变量可在冻结模型中测量，并可由 MATLAB、COMSOL 和前人公开/入库结果交叉核对。

## Method

- **Type**：Quantitative。
- **Specific method**：确定性多物理场有限元基准验证 + 分层参数扫描 + 曲率/梯度敏感性分析。
- **Unit of analysis**：一个冻结的几何--材料--边界--载荷--网格--输出点组合。
- **Evidence levels**：
  1. Level A：本项目 MATLAB 与本项目独立 COMSOL 同工况结果；
  2. Level B：本项目结果与钱沈云论文表格/COMSOL 数值；
  3. Level C：本项目代码与钱沈云代码同工况复跑；
  4. Level D：同一程序内部缩放或矩阵自洽，仅用于诊断，不作为独立正确性证据。

## Data Strategy

### Existing primary simulation data

- `output/results_static.csv`：无孔隙 5 FG × 9 体积分数 × 3 载荷，共 135 行。
- `output/results_static_porous.csv`：含孔隙设计空间，共 390 行。
- `outputs/manual-20260714-fgmeet-validation/`：新口径机械力致位移验证。
- `outputs/manual-20260611-fgmeet/electro-magneto-validation/`：300 V、200 A 与位移反推场量的历史证据。

### New primary simulation data

1. 300 V 单激励 MATLAB--COMSOL 独立对标；
2. 200 A 单激励 MATLAB--COMSOL 独立对标；
3. 0.5/1/2 mm 位移反推电势、磁势的独立或明确分级验证；
4. 圆柱壳曲率扫描：平板基准与 R = 1.0、0.4、0.3、0.2 m；
5. U/X 两类代表梯度 × 五种曲率 × 三类载荷，共 30 个 MATLAB 主运行；
6. 代表性曲率/梯度点的 COMSOL 核验与至少 10% 历史结果确定性复跑抽检。

### Secondary evidence

- 钱沈云 2026 论文及配套代码；
- 赵亚飞论文、圆柱壳代码与已保存结果；
- Phase 2 检索并逐条核实的近期同行评审文献。

## Frozen Baseline

| Item | Frozen value |
|---|---|
| Geometry | 300 mm × 300 mm × 6 mm；圆柱壳只改变曲率半径 |
| Layers | 10 |
| Boundary | CFFF 主线；CFCF 仅作稳健性附录 |
| Material | BaTiO3/CoFe2O4，逐层混合律 |
| Reference FG | U，Vf0 = 0.6 |
| Mechanical load | 15000 Pa，符号按现有 MATLAB 口径冻结 |
| Electric load | 上下表面 ±300 V，报告总跨度与边界值 |
| Magnetic load | 上下表面 ±200 A 磁势，报告总跨度与边界值 |
| Stiffness scale | 1.0，禁止用统一刚度缩放追数 |
| Primary output | 自由端中点/几何中心的法向位移；曲壳按参数网格节点定义，不用平板笛卡尔最近点替代 |
| Secondary output | 15 点位移、层平均电势/磁势 span、磁电效率 |

## Analytical Framework

1. **Model verification**：检查自由度、单位、边界、载荷方向、材料层顺序、输出点和矩阵维数。
2. **Mesh verification**：相邻网格主输出变化小于 0.5% 才进入最终表格。
3. **Independent validation**：机械、300 V、200 A 分别建模，禁止混合载荷后反推误差来源。
4. **Error metrics**：
   - 主位移相对误差：`|M-C|/|C|`；
   - 小位移点同时报告绝对误差和以最大位移归一化的误差，避免小分母放大；
   - 场量同时报告边界值、层平均 span 与符号约定。
5. **Sensitivity analysis**：以平板 U/Vf0=0.6 为基准，报告响应比、百分比变化、极差和排序；确定性全因子结果不使用虚假的显著性检验。
6. **Interaction analysis**：比较曲率 × FG 类型、曲率 × 载荷类型的差分响应；仅在数据完整时报告交互项。
7. **Reproducibility**：抽取至少 10% 历史算例重新运行；确定性结果要求数值与存档在浮点容差内一致。

## Acceptance Gates

| Gate | Pass criterion |
|---|---|
| Mechanical primary validation | 自由端中点 MATLAB--COMSOL 相对误差 ≤ 1% |
| Electric primary validation | 300 V 主位移对独立 COMSOL/论文基准 ≤ 1% |
| Magnetic primary validation | 200 A 主位移对独立 COMSOL/论文基准 ≤ 1%；若仅能建立等效模型，必须标注模型等级 |
| Inverse sensing | 至少一个独立证据源；只有同源代码复跑时不得写成 COMSOL 直接验证 |
| Mesh convergence | 相邻网格主输出变化 ≤ 0.5% |
| Historical rerun | 抽检记录无未解释差异；失败结果完整保留 |
| Innovation result | 平板与至少三种非零曲率均成功；至少 U/X 两种梯度和三类载荷可比较 |

## Validity Criteria

| Criterion | Strategy |
|---|---|
| Internal validity | 单激励、冻结口径、禁止刚度追数；每次只改变一个验证因素。 |
| Construct validity | 区分电势边界值、磁势边界值、层平均 span、中心位移与自由端位移。 |
| Numerical reliability | 网格收敛、确定性复跑、日志与 SHA-256 清单。 |
| External validity | 与钱沈云论文表格、钱沈云/赵亚飞代码和独立 COMSOL 代表工况交叉核对。 |
| Traceability | 每个论文表格和图回链到 CSV/MAT/COMSOL 日志及生成脚本。 |

## Limitations by Design

- COMSOL 6.0 的 45×45 完整耦合随动压力模型存在约 33 GB 内存上限；采用分级网格和代表性高网格，不将失败运行当作结果。
- COMSOL 对磁势的实现可能依赖等效耦合或用户 PDE；若无法做到与 MATLAB 完全同构，证据等级必须降级并在局限中说明。
- 曲壳现有 MATLAB 脚本的中心点取法与平板包装器不同；在扫描前必须统一为参数网格中心节点。
- 本研究为线性确定性计算，不能直接外推到材料随机性、制造误差和大变形实验样件。
- 动力结果保留为补充材料；核心结论以静力双向耦合和曲率--梯度效应为主。

## Ethical Considerations

- 无人/动物受试者，不需要 IRB。
- 不虚构文献、COMSOL 结果或不存在的独立验证。
- 失败工况、内存中止和不支持的磁场实现必须报告。
- 最终论文保留 AI 辅助整理与验证说明，作者负责最终审阅。

## Reporting Standard

- IMRaD 结构；
- 数值验证、网格收敛、参数冻结、负结果与可复现入口单列；
- 结果正文只使用已通过相应证据门槛的数据。

## Preregistration

- **Recommended**：No formal registry required；这是确定性计算研究。
- **Internal freeze**：Yes；本文件和 `experiment_matrix.csv` 作为分析前冻结方案，后续偏离必须记录。

