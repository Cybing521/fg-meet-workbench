# Research Question Brief

## Material Passport

- Origin Skill: `deep-research`
- Origin Mode: `full`
- Origin Date: `2026-07-15T10:51:58+08:00`
- Verification Status: `UNVERIFIED`
- Version Label: `research_v1`
- Upstream Dependencies: `force_displacement_validation_20260714`, `five_point_validation_20260612`, `paper_main_zh_existing`

## Research Question

在统一几何、材料、边界、载荷与输出口径并经 COMSOL 独立验证后，曲率与厚度方向功能梯度如何改变含孔隙 FG-MEE 板壳的双向机--电--磁耦合响应？

## Sub-Questions

1. MATLAB 与 COMSOL 在机械载荷、300 V 电势和 200 A 磁势单激励下的主位移口径能否稳定进入 1% 以内？
2. 平板与不同曲率圆柱壳的机械挠度、电致位移、磁致位移和位移反推电/磁势如何变化？
3. U/V/X/O/P 功能梯度、体积分数和孔隙参数对上述响应的主效应与交互效应分别有多大？

## FINER Scores

| Criterion | Score (1--10) | Basis |
|---|---:|---|
| Feasible | 8 | MATLAB R2026a、COMSOL 6.0、板与圆柱壳输入文件、既有批处理结果均已在本机找到；新增工作集中在独立电/磁验证与统一曲率输出。 |
| Interesting | 8 | 同时连接致动与传感，并比较平板/曲壳及梯度材料，能够回答设计参数如何改变耦合性能。 |
| Novel | 7 | “曲率 × 功能梯度 × 双向耦合”的组合具有潜在创新性，但必须在 Phase 2 通过文献检索确认，当前不作已证实的首创声明。 |
| Ethical | 10 | 纯计算研究，不涉及人或动物受试者；主要风险是结果与来源误述，可通过证据分级和 AI 使用说明控制。 |
| Relevant | 9 | 直接对应导师要求的平板、翘曲/圆柱壳、功能梯度与 MATLAB--COMSOL 交叉验证。 |
| **Average** | **8.4** | 满足进入完整研究模式的门槛。 |

## Scope

- **In scope**：300 mm × 300 mm × 6 mm、10 层、CFFF 主边界；BaTiO3/CoFe2O4 FG-MEE；线性静力；机械、300 V、200 A 三种单激励；0.5/1/2 mm 位移反推场量；平板与圆柱壳；U/V/X/O/P 梯度；体积分数与既有孔隙模型；MATLAB 与 COMSOL 的独立数值验证。
- **Out of scope**：实验室样件测试、材料微观烧结模拟、疲劳/断裂、随机缺陷、全参数几何非线性动力壳分析、同时叠加力/电/磁后再判定单一误差来源。
- **Domain**：计算固体力学、多物理场有限元、功能梯度智能结构。
- **Timeframe**：以 2026-07-15 冻结的本地代码、论文与仿真结果为基线；后续结果按版本追加。
- **Geography**：不适用；研究对象为通用数值模型。
- **Population**：FG-MEE 方板与圆柱壳数值算例。

## Methodology Type

Quantitative：确定性计算实验、数值基准验证与参数敏感性分析。

## Theoretical Framework

全耦合磁--电--弹性有限元框架，一阶剪切变形板壳理论，厚度方向逐层功能梯度混合律，以及 verification--validation--sensitivity 三层证据框架。

## Hypothesis

在不使用刚度缩放的统一口径下，机械、电势和磁势单激励的主位移能够与独立 COMSOL/论文基准保持约 1% 的一致性；曲率和表层富集梯度将改变弯曲刚度与耦合矩阵贡献，从而对致动位移和反向传感幅值产生可区分的交互影响。

## Keywords

FG-MEE；magneto-electro-elastic；functionally graded；porous plate；cylindrical shell；bidirectional coupling；COMSOL validation；finite element method；electric actuation；magnetic actuation。

## Candidate Questions Considered

| Candidate | FINER Avg | Decision |
|---|---:|---|
| 曲率与功能梯度如何影响经独立验证的双向耦合响应？ | 8.4 | 选定，可同时承载验证与创新。 |
| MATLAB 与 COMSOL 的三类载荷误差能否降至 1%？ | 7.0 | 适合作为验证子问题，但单独成文创新性不足。 |
| 孔隙率如何影响平板耦合响应？ | 7.4 | 已有较完整稿件和结果，保留为主数据层，但需增加曲壳与新验证口径。 |
| 动力与几何非线性下的全参数 FG-MEE 曲壳响应如何变化？ | 6.2 | 对当前小论文过宽，降为后续研究。 |

