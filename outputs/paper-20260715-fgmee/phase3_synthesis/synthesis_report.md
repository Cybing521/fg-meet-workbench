# 证据综合报告

## 2026-07-15 数值实证补充

本报告以下主体反映 Stage 2 执行前的文献综合；其中“电/磁正向加载仍主要对照论文表格、反向感知尚待独立闭合”已经被后续本地试验推进，现按以下新证据更新：

- 300 V 与 200 A 的独立三维直接场 COMSOL 模型均已完成 10×10、15×15、20×20 网格求解，场强和网格门槛通过；20×20 相对 MATLAB 的偏差为 10.7727% 和 9.2679%。多组区分性试验将主因冻结为 LRT5 板与三维实体的模型非同构，而非粗网格或场强错误。
- MATLAB 反传感旧结果存在十层热释电/热释磁重复装配。修正后 0.5 mm 为 78.4803 V、0.0309000 A；20×20 COMSOL 三维力学—冻结本构后处理与修正版差异为 3.4654%，证据等级为 B，尚不是完全独立电磁 PDE。
- 曲率—功能梯度 30 行筛选已完成。R=0.4 m 代表点通过 20→30 网格检查，电致与磁致 U/X 梯度—曲率交互均约 1.4683 个百分点，为最大网格变化的 70.6 倍；原“交互仍是假设”已推进为代表点已分辨、全半径高精度图谱仍待扩展。

因此当前研究主线可从“待检验交互”升级为“经代表点网格验证的致动梯度—曲率非加性交互”，但直接场跨软件 `<1%` 只能在建立同构壳/实体对照后重新验收。完整本地证据见 `experiments/stage2_experiment_result.md` 和 `phase4_reporting/stage2_validation_report_20260715_v2.tex`。

## 文献矩阵

| 来源 | 核心主题 | 结构/尺度 | 方法或证据 | 对本研究的作用 | 质量 |
|---|---|---|---|---|---|
| Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> | 全耦合、COMSOL 对照 | 板 | 全耦合计算 + COMSOL | 电/磁加载位移主基准 | A / VI |
| Zhao et al. (2024) <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract--> | 梯度、孔隙、热 | 圆柱壳 | 有限元 | 否定“多孔曲壳首次” | A / VI |
| Zhang et al. (2022) <!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract--> | FG-MEE 静动态 | 板与壳 | 计算模型 | 否定“FG-MEE 板壳首次” | A / VI |
| Zhao et al. (2022) <!--ref:zhao2022_cntmee--><!--anchor:section:Abstract--> | CNT 增强、非线性 | FG 板 | 非线性计算 | 多相材料边界 | B+ / VI |
| Zhou and Qu (2023) <!--ref:zhou2023_migam--><!--anchor:section:Abstract--> | 热耦合、静动态 | MEE 结构 | 等几何分析 | 方法对照 | A / VI |
| Tarkashvand et al. (2025) <!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract--> | 多孔、移动热流 | 圆柱壳 | 瞬态多物理场 | 近期复杂工况边界 | A / VI |
| Gan and She (2024) <!--ref:gan2024_imperfect_shell--><!--anchor:section:Abstract--> | 初始缺陷、非线性 | 圆柱壳 | 瞬态计算 | 几何缺陷边界 | A / VI |
| Pham Hoang Tu et al. (2024) <!--ref:tran2024_double_curved--><!--anchor:section:Abstract--> | 双曲、冲击 | 浅壳 | 等几何分析 | 曲率与动态边界 | A / VI |
| Ellouz et al. (2023) <!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract--> | FG、双曲、非线性 | 浅壳 | 改进 FSDT | 曲率创新反证 | A / VI |
| Özmen (2023) <!--ref:ozmen2023_nanoplates--><!--anchor:section:Abstract--> | 热机、振动、屈曲 | 纳米板 | 高阶理论 | 尺度边界 | B / VI |
| Koç et al. (2024) <!--ref:koc2024_porous_core--><!--anchor:section:Abstract--> | MEE 面层、FG 多孔芯 | 纳米板 | 非局部应变梯度 | 多孔组合边界 | B / VI |
| Esen et al. (2025) <!--ref:esen2025_porous_nanoplate--><!--anchor:section:Abstract--> | 多孔 FG-MEE、温变 | 夹层纳米板 | 高阶理论 | 多孔热屈曲边界 | B+ / VI |
| Kar and Srinivas (2025) <!--ref:kar2025_porous_microplate--><!--anchor:section:Abstract--> | 多孔、冲击、优化 | 微板 | 动力学与优化 | 优化创新边界 | B+ / VI |
| Brischetto et al. (2025) <!--ref:brischetto2025_3d--><!--anchor:section:Abstract--> | 三维精确静力 | 多层板 | 3D 解析/计算 | 高保真方法基准 | A / VI |
| Gong et al. (2025) <!--ref:gong2025_comsol3d--><!--anchor:section:Abstract--> | 通用 3D 有限元 | 多相复合体 | 3D FE / COMSOL 线索 | 独立实现参照 | A / VI |
| Dat et al. (2022) <!--ref:dat2022_auxetic--><!--anchor:section:Abstract--> | 负泊松、冲击 | 层合板 | 振动分析 | 相邻动态证据 | B+ / VI |
| Tassi et al. (2022) <!--ref:tassi2022_effective--><!--anchor:section:Abstract--> | 有效材料性质 | 多相材料 | 条件化微观力学 | 参数转换约束 | A / VI |
| Zhou et al. (2022) <!--ref:zhou2022_enriched--><!--anchor:section:Abstract--> | 瞬态响应 | MEE 结构 | 富集有限元 | 数值方法对照 | A- / VI |
| Sladek et al. (2013) <!--ref:sladek2013_large_deflection--><!--anchor:section:Abstract--> | 大挠度 | MEE 板 | MLPG | 经典非线性方法 | B+ / VI |
| Vinyas and Kattimani (2018) <!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract--> | 颗粒排列、热耦合 | MEE 板 | 静态计算 | BaTiO3/CoFe2O4 参数基础 | A- / VI |
| Kondaiah et al. (2012) <!--ref:kondaiah2012_cantilever--><!--anchor:section:Abstract--> | 热耦合 | 悬臂梁 | 数值算例 | 经典耦合基准 | B / VI |
| Nan et al. (2008) <!--ref:nan2008_review--><!--anchor:section:Abstract--> | 磁电复合材料基础 | 材料层 | 综述 | 物理与历史基础 | A / VII |
| Zhao (2023) <!--ref:zhao2023_dissertation--><!--anchor:page:95-102--> | 曲率、梯度、孔隙、双向输出 | 板与圆柱壳 | 博士论文计算体系 | 最直接前人边界与复现源 | A- / VI |

## 关键主题

### 主题一：研究对象已经成熟，创新必须从“对象”转向“证据链”

**证据强度：强。** 7 个直接来源，Level VI 为主。

文献不是只覆盖单一 MEE 平板。FG-MEE 板与壳的静动态体系已经形成（Zhang et al., 2022）<!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract-->；多孔 FG-MEE 圆柱壳已经进入热载荷研究（Zhao et al., 2024）<!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->；双曲浅壳、几何非线性、初始缺陷和移动热流也分别被扩展（Ellouz et al., 2023）<!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->、（Gan & She, 2024）<!--ref:gan2024_imperfect_shell--><!--anchor:section:Abstract-->、（Tarkashvand et al., 2025）<!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract-->。本地博士论文还把曲率、厚度梯度、孔隙模式及电/磁势输出串联在同一研究体系内（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->。

因此，单纯增加一个曲率工况或孔隙参数不会自然形成贡献。可辩护的转向是：把不同结构类型放在完全一致的材料、边界、载荷与输出点口径中，检验跨平台误差和参数交互是否稳定。这个判断的锚点是上述来源共同覆盖了“对象”，而没有在本轮可核内容中展示与本项目相同的三路、五类工况、统一误差审计闭环。

### 主题二：验证证据存在，但“接近”不能自动等同“独立”

**证据强度：中等偏强。** 5 个方法/验证来源，Level VI。

Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 给出了 MATLAB 型全耦合模型与 COMSOL 的直接位移对照；其 ±300 V 和 ±200 A 表格值非常接近，说明在口径一致时，基础线性加载的数值差异应当很小。近期三维精确解和通用 3D 有限元工作也说明，低阶板壳模型、三维模型和有限元实现之间存在可设计的交叉基准（Brischetto et al., 2025）<!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->、（Gong et al., 2025）<!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->；等几何与富集有限元则提供了不同离散路线（Zhou & Qu, 2023）<!--ref:zhou2023_migam--><!--anchor:section:Abstract-->、（Zhou et al., 2022）<!--ref:zhou2022_enriched--><!--anchor:section:Abstract-->。

不过，方法多样性恰好揭示“独立”的最低要求：若两份结果共享材料转换脚本、刚度装配或输出后处理，就只能证明实现一致，而不能排除共同错误。后续执行已经补齐电、磁三维直接场模型和反传感三维力学交叉实现，但前者与 MATLAB LRT5 板并非同构，后者仍共享冻结本构后处理。综合结论因此更新为“机械链路有较强基线，电/磁运行与网格闭环完成，严格同构正向验证和完全独立反向 PDE 尚待闭合”。锚点来自当前实验矩阵与正式日志，而不是文献声望。

### 主题三：材料参数转换是跨平台误差的高风险接口

**证据强度：中等。** 4 个来源，Level VI/VII。

磁电复合材料的宏观响应依赖组分、连接方式与有效性质（Nan et al., 2008）<!--ref:nan2008_review--><!--anchor:section:Abstract-->；BaTiO3/CoFe2O4 颗粒排列会改变板的耦合静态响应（Vinyas & Kattimani, 2018）<!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract-->；全耦合有效性质又可以通过条件化微观力学建立（Tassi et al., 2022）<!--ref:tassi2022_effective--><!--anchor:section:Abstract-->。这三条证据共同说明，“MATLAB 与 COMSOL 输入了同样的若干标量”并不足以证明材料模型等价，必须继续核对张量分量、剪切项顺序、极化方向、单位和符号约定。

赵亚飞的前人体系展示了曲率与厚度梯度下的电/磁势输出（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->，但其数值只能在层序、坐标方向和输出定义相同时作为量级基准。因而后续材料护照应成为实验输入的一部分，而不是论文附录中的事后说明。

### 主题四：曲率、梯度和孔隙可能交互，但当前证据不能预先宣称非加性

**证据强度：新兴。** 多个来源分别覆盖因素，但本轮没有取得同一口径三因素完整交互表。

文献分别证明曲率/双曲几何、功能梯度、多孔分布和热/冲击条件会进入 MEE 响应问题（Zhao et al., 2024）<!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->、（Ellouz et al., 2023）<!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->、（Tarkashvand et al., 2025）<!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract-->。微/纳尺度研究还把多孔芯、温变材料和优化纳入模型（Koç et al., 2024）<!--ref:koc2024_porous_core--><!--anchor:section:Abstract-->、（Esen et al., 2025）<!--ref:esen2025_porous_nanoplate--><!--anchor:section:Abstract-->、（Kar & Srinivas, 2025）<!--ref:kar2025_porous_microplate--><!--anchor:section:Abstract-->。

这些来源支持“值得测试交互”，但不支持“交互已经存在且显著”。只有后续因子设计显示二阶项超过网格误差和跨平台误差，且在复算中保持符号与效应量，才能把非加性交互写成发现。当前最稳妥的理论连接是：材料梯度改变局部耦合刚度，曲率改变膜-弯耦合，孔隙改变有效模量；三者可能通过同一平衡方程交汇，但交汇不必然产生统计或工程上显著的非加性。

### 主题五：现有证据是数值有效性证据，不是物理实验有效性证据

**证据强度：强。** 23/23 纳入来源均为计算、理论或综述。

文献可以支持模型间的一致性、收敛性和参数趋势，但不能证明真实样件在 300 V、200 A 或给定位移下必然产生同样响应。即使三维有限元、精确解和 COMSOL 相互接近（Brischetto et al., 2025）<!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->、（Gong et al., 2025）<!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->，其结论仍受材料常数、理想边界和尺度假设约束。论文必须把“数值验证”“文献对标”和“实验验证”分开表述。

## 矛盾与解释

| 表面张力 | 对照证据 | 综合解释 |
|---|---|---|
| 基础加载误差应接近零 vs. 当前部分工况出现 0.92%--2.5% | Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 的同口径表格很接近；项目旧结果仍有更大差异 | 不是理论矛盾，优先解释为材料张量、边界、输出点、网格或误差分母未完全统一；需独立 COMSOL 复算判定 |
| 电势过大 vs. 磁势过小 | Zhao (2023) <!--ref:zhao2023_dissertation--><!--anchor:page:100-102--> 展示层间输出量级随边界和梯度变化 | 数值量级不能脱离位移幅值、单位和参考势定义比较；先复现同工况，再做 0.5/1.0 mm 缩放 |
| 曲率/孔隙已经研究 vs. 仍可研究曲率×梯度×孔隙 | Zhao et al. (2024) <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract--> 和 Ellouz et al. (2023) <!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract--> 覆盖单项或组合问题 | “研究对象存在”与“同口径交互图谱存在”不是同一命题；后者只能以谨慎检索限定语提出，并需数据证明 |
| 2 mm 可线性缩放 vs. 全耦合/非线性文献提示条件依赖 | Sladek et al. (2013) <!--ref:sladek2013_large_deflection--><!--anchor:section:Abstract--> 与 Gan and She (2024) <!--ref:gan2024_imperfect_shell--><!--anchor:section:Abstract--> 研究大挠度或非线性 | 在线性小变形、线性材料与固定边界下可以缩放；若几何、材料或接触非线性启用，必须重新求解而非整体除法 |

## 跨论文张力清单

```yaml
cross_paper_tensions:
  - pair_id: CP-001
    paper_a: zhang2026_full
    paper_b: zhao2023_dissertation
    candidate_basis: shared construct/outcome/measure
    overlap_topic: electric and magnetic loading or sensing output magnitudes
    a_finding: closely matched displacement values are reported for fixed voltage and current validation cases
    a_evidence_pointer: local original PDF Tables 4-5
    b_finding: electric and magnetic potentials are reported through the thickness for curved FG configurations
    b_evidence_pointer: local dissertation pages 95-102
    pair_assessment: conditional_difference
    resolution_status: resolved_in_synthesis
    resolution_pointer: Synthesis Report > Contradictions and explanations, row 2
    scholar_confirmation: pending
  - pair_id: CP-002
    paper_a: zhang2022_fgmee_shell
    paper_b: zhao2024_porous_shell
    candidate_basis: shared RQ subtopic
    overlap_topic: functionally graded magneto-electro-elastic shells
    a_finding: static and dynamic FG-MEE plate and shell analysis is within scope
    a_evidence_pointer: official abstract
    b_finding: porous FG-MEE cylindrical shells under thermal loading are within scope
    b_evidence_pointer: official abstract
    pair_assessment: no_material_conflict
    resolution_status: not_applicable
    scholar_confirmation: pending
  - pair_id: CP-003
    paper_a: belbachir2023_double_curved
    paper_b: gan2024_imperfect_shell
    candidate_basis: shared construct/outcome/measure
    overlap_topic: geometric nonlinearity in curved MEE shells
    a_finding: geometrically nonlinear FG-MEE doubly curved shallow shells are modeled with improved FSDT
    a_evidence_pointer: official abstract
    b_finding: initial geometric imperfection is included in nonlinear transient MEE cylindrical-shell response
    b_evidence_pointer: official abstract
    pair_assessment: conditional_difference
    resolution_status: resolved_in_synthesis
    resolution_pointer: Synthesis Report > Contradictions and explanations, row 4
    scholar_confirmation: pending
  - pair_id: CP-004
    paper_a: tassi2022_effective
    paper_b: vinyas2018_arrangement
    candidate_basis: shared construct/outcome/measure
    overlap_topic: effective coupled properties of multiferroic composites
    a_finding: fully coupled effective properties are derived using conditioned micromechanics
    a_evidence_pointer: official abstract
    b_finding: BaTiO3/CoFe2O4 particle arrangement affects static plate response
    b_evidence_pointer: official abstract
    pair_assessment: conditional_difference
    resolution_status: resolved_in_synthesis
    resolution_pointer: Synthesis Report > Key themes > Theme 3
    scholar_confirmation: pending
  - pair_id: CP-005
    paper_a: brischetto2025_3d
    paper_b: gong2025_comsol3d
    candidate_basis: shared RQ subtopic
    overlap_topic: three-dimensional MEE modeling
    a_finding: multilayered-plate static response is treated with a 3D exact formulation
    a_evidence_pointer: official abstract
    b_finding: multiphase-composite vibration and dynamics are treated with a general 3D FE model
    b_evidence_pointer: official abstract
    pair_assessment: insufficient_overlap
    resolution_status: not_applicable
    scholar_confirmation: pending
  - pair_id: CP-006
    paper_a: zhao2024_porous_shell
    paper_b: koc2024_porous_core
    candidate_basis: agent-noted cross-cluster
    overlap_topic: porosity combined with MEE functional grading
    a_finding: macroscopic porous FG-MEE cylindrical shells are studied under thermal loading
    a_evidence_pointer: official abstract
    b_finding: nanoscale plates combine MEE face layers with an FG porous core under nonlocal strain-gradient elasticity
    b_evidence_pointer: official abstract
    pair_assessment: conditional_difference
    resolution_status: flagged_unresolved
    scholar_confirmation: pending
```

**覆盖说明：**语料包含 23 篇/部来源，本次按共享研究问题、共享构念/输出和跨主题簇信号审查了 6 对候选。该清单是召回受限的建议性扫描，不是完整的 253 对穷举；未被当前主题邻域暴露的跨阵营矛盾仍可能存在。书目耦合仅可作为纳入信号，未用于排除候选。`scholar_confirmation` 保持 pending，等待研究者确认。

## 知识缺口

1. **方法缺口：同构性与完全独立性仍不足。** 电、磁直接场 COMSOL 已运行并完成网格检查，但与 LRT5 板是不同模型形式；反传感已取得 B 级三维力学交叉结果，但势场仍由冻结本构后处理。影响：当前可支撑敏感性与跨实现一致性，不能支撑“全部链路独立且小于 1%”。
2. **测量缺口：输出口径不统一。** 不同来源使用中心点、自由端、层平均、表面势或无量纲量。影响：图形趋势相似不能直接转化为相对误差。
3. **交互缺口：两因素代表点已分辨，三因素仍不足。** R=0.4 m 的曲率×梯度致动交互已超过网格误差，但孔隙尚未纳入同一宏观板壳、同一输出口径的完整三因素设计。影响：可报告代表点两因素交互，不能外推为曲率×梯度×孔隙普遍规律。
4. **实验缺口：全部纳入证据为计算/理论。** 影响：结论上限是数值一致性和参数敏感性，不是器件实测性能。
5. **失败证据缺口：多数论文只展示成功收敛结果。** 影响：内存失败、病态参数和符号错误的边界不清楚，本研究应保留失败日志和判据。
6. **可重复性缺口：材料张量、坐标和势参考点常散落于正文。** 影响：必须用材料护照和机器可读工况表冻结接口。

## 证据收敛图

```text
强       [==========] FG-MEE 板壳、曲率与孔隙均已有研究（7+ 来源，Level VI）
中强     [========  ] 跨数值方法验证可行且必要（5 来源，Level VI）
中等     [======    ] 材料参数转换显著影响耦合响应（4 来源，Level VI/VII）
新兴     [===       ] 曲率×梯度×孔隙存在非加性交互（尚无同口径直接证据）
缺口     [          ] 实验测量验证（0 来源）
```

## 理论整合

可将后续研究组织为“接口--平衡--输出”三层框架。接口层冻结材料耦合张量、坐标、极化、单位和势参考；平衡层分别由机械、静电与静磁方程耦合，曲率改变膜-弯传递，梯度与孔隙改变厚度方向有效系数；输出层统一到指定几何点/参数点的位移、电势和磁势，并采用同一误差定义。该框架解释了为什么相同材料名称不保证同一数值，也解释了为什么交互效应必须在网格与跨平台误差之上才有物理讨论价值。

## 反方审查后冻结的分析门槛

1. **误差门槛：**主指标采用 `|x_MATLAB-x_COMSOL|/|x_ref|`，`x_ref` 固定为网格收敛后的 COMSOL 值；当 `|x_ref|` 小于预先登记的量级阈值时，切换为绝对误差并同时报告归一化误差。所有通过结果还必须满足符号一致、网格加密变化小于 0.5%，且求解器残差/终止状态正常。
2. **独立性门槛：**COMSOL 证据包必须包含模型树、材料张量分量映射、单位、极化/坐标、边界、网格、求解器和原始表格导出；不得用前人 MATLAB 装配矩阵或同一后处理程序来证明独立性。
3. **交互门槛：**先冻结主效应子集，再计算预指定二阶交互；只有交互幅值高于 MATLAB/COMSOL 差异与网格误差的合成上界，且分层复算保持方向一致，才进入主要结论。
4. **尺度门槛：**微/纳板文献仅用于说明主题饱和与方法边界，不参与宏观板壳参数范围和效应量的定量合并。
5. **创新门槛：**在取得并全文核对最相近的 5 篇论文前，只能写“本轮定向检索未见”，不得写“尚无研究”或“首次”。
6. **物理效度门槛：**全文统一使用“跨平台数值一致性”；无样件测量时不得升级为“实验验证”或“物理真实性证明”。

## 综合局限

- 只有 2/23 条来源完成本地原始全文关键页核查；其余主要为正式摘要级证据。
- 本轮是定向证据审计，不是穷尽数据库的系统综述，不能支撑绝对“尚无研究”。
- 全部来源为计算、理论或综述，缺少实验数据。
- 结构尺度从宏观壳到微/纳板不等，跨尺度只能用于概念与方法边界，不能混合绝对数值。
- 曲率×梯度致动交互已在 R=0.4 m 代表点得到网格分辨；全半径高精度曲线、孔隙三因素与独立曲壳对照仍需补齐，才能形成完整投稿证据链。
