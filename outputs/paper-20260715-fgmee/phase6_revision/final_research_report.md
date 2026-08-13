# 多孔功能梯度磁电弹板壳研究的证据审计与独立数值验证方案

**完整模式研究报告（修订版）**  
日期：2026-07-15  
状态：Stage 1 研究基础完成；电/磁/反向感知与曲率交互实验尚未执行完毕

## 摘要

本报告审计含孔隙功能梯度磁电弹（FG-MEE/FG-MEEP）板壳小论文的现有证据，并把后续工作转化为可执行验证方案。定向调查筛选 31 条候选记录，纳入 22 篇期刊论文和 1 篇博士论文。证据表明，FG-MEE 板壳、曲率、多孔圆柱壳和双向场响应均已有研究；“增加翘曲、功能梯度或孔隙”不能单独构成创新。现阶段已经形成机械载荷位移的独立 MATLAB--COMSOL 基线，但 ±300 V、±200 A 和位移反演电/磁势尚未形成完整独立证据包。修订后的研究贡献定位为：统一材料张量、边界、坐标和输出口径，建立 MATLAB--COMSOL--文献三路数值一致性闭环，并用预指定对比检验曲率、梯度与孔隙交互。1% 仅作为工程目标，不是正确/错误分界；判定还包括近零绝对误差、符号、网格变化、求解状态和失败分母。如果交互不高于合成数值不确定度，研究将如实报告受限空结果和误差诊断，不更换指标。该方案只评价数值一致性与参数敏感性，不声称实验或物理真实性验证。

**关键词：** 磁电弹；功能梯度；多孔板壳；COMSOL；数值一致性；证据审计；可重复性

## 1. 研究问题与定位

磁电弹结构通过耦合本构连接机械、电和磁响应。多铁磁电复合材料的物理基础已有系统综述（Nan et al., 2008）<!--ref:nan2008_review--><!--anchor:section:Abstract-->，结构研究也从悬臂和平板扩展到功能梯度板壳。Zhang et al. (2022) <!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract--> 已研究 FG-MEE 板壳静动态响应；Ellouz et al. (2023) <!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract--> 覆盖双曲 FG-MEE 浅壳几何非线性；Zhao et al. (2024) <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract--> 直接研究多孔 FG-MEE 圆柱壳。赵亚飞博士论文还包含多组曲率、梯度、孔隙及厚度方向电/磁势输出（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->。

这些证据否定“对象式创新”：平板加翘曲、普通材料加功能梯度，或致密结构加孔隙都不足以证明贡献。修订后的问题是：

> 在统一几何、材料、边界与输出口径下，经 MATLAB--COMSOL--文献三路验证后，曲率、厚度梯度与孔隙分布对 FG-MEE 板壳正向致动、反向感知和跨平台数值一致性有何交互影响？

本报告是该问题的证据审计和验证协议，不是完成态结果论文。只有计划实验执行并通过冻结门槛后，才可使用“经独立数值验证的曲率--梯度交互”这一结果型标题。

## 2. 证据基础与创新边界

### 2.1 来源审计

文献调查日期为 2026-07-15，时间范围为 2008--2026，核心关注 2021--2026。31 条候选级记录中纳入 23 条，排除 8 个仅涉及压电、压磁、普通功能梯度、材料制备或不可核聚合页的结果簇。22 篇 DOI 论文全部由 OpenAlex 匹配，21 篇同时由 Crossref 匹配；余 1 篇由出版社页面补验。Semantic Scholar 本轮接口降级，按 degraded 记录，不解释为文献不存在。

两份本地原始 PDF 完成关键页视觉核查，其余主要完成 DOI、出版社页面和摘要级核验。因而创新措辞必须保持“本轮定向检索未见”，不能写成穷尽性的“首次”或“尚无研究”。提交前还必须阅读全文核对 Zhang 2022、Zhao 2024、Ellouz 2023、Tarkashvand 2025 和 Gong 2025 五个最相近来源。

### 2.2 可辩护贡献

Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 的原始表格显示，在 CFFF、中心点与载荷定义统一时，±300 V 工况的两种结果均约为 -5.23×10^-2 mm，±200 A 工况约为 1.75×10^-1 mm 与 1.73×10^-1 mm。这证明基础工况可以形成紧密数值对照，但不证明任意代码或任意 1% 阈值都正确。三维精确解和通用三维有限元还提供不同建模层级的参照（Brischetto et al., 2025）<!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->、（Gong et al., 2025）<!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->。

因此，最可辩护的贡献不是“使用 COMSOL”，而是能证明 COMSOL 模型独立建立，并把所有差异追溯到材料张量、坐标、单位、边界、网格或输出。若预指定交互高于数值不确定度，可进一步报告设计规律；若没有，则报告有界空结果、失败分布和跨平台诊断，保持验证/可重复性贡献。

## 3. 理论与诊断框架

研究采用“接口--平衡--输出”三层框架。

接口层冻结几何、层序、极化、材料张量、单位、参考势与坐标。BaTiO3/CoFe2O4 组分排列会改变板的静态耦合响应（Vinyas & Kattimani, 2018）<!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract-->，全耦合有效性质又取决于具体均匀化方法（Tassi et al., 2022）<!--ref:tassi2022_effective--><!--anchor:section:Abstract-->。因此，“两边用了同一材料名称”不是等价性证据；必须逐分量映射弹性、压电、压磁、介电、磁导与磁电耦合项。

平衡层耦合机械、静电和静磁方程。曲率改变膜--弯传递，梯度与孔隙改变厚度方向有效系数。已有文献分别研究多孔曲壳、双曲壳和移动热载荷（Zhao et al., 2024）<!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->、（Ellouz et al., 2023）<!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->、（Tarkashvand et al., 2025）<!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract-->；这些证据支持检验交互，却不预先证明交互显著。

输出层固定几何点或参数坐标、物理分量、点值/层平均和参考势。平板与曲壳的“中心”同时记录归一化参数坐标和全局坐标。不同点位极值、表面值和层平均不得直接进入同一误差式。

## 4. 当前证据状态

机械力--位移代表工况已获得 0.710707% 的 MATLAB--COMSOL 差异，证据位于 `outputs/manual-20260714-fgmeet-validation/latex-report/force_displacement_validation_20260714.tex`。该工况可称为独立机械基线。

电、磁正向工况已与 Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 的表格对照，现有差异约为 0.08%--0.92%，但本项目自己的 COMSOL 模型树、原始表格和材料分量映射尚未成套保存。位移反演电势/磁势的同工况复跑差异约为 10^-12，但两次计算来自前人程序链，只能称为实现一致性检查。

这三项待办均为必要内容：±300 V 正向位移、±200 A 正向位移，以及位移反演电/磁势。它们不完成，就不能声称统一双向闭环。特别是“200 A”不是完整边界条件；运行前必须从前人公式和模型中冻结它对应的磁标势差、表面电流/电流势或等效广义载荷、方向和 SI 单位。当前状态明确记为 `magnetic_load_semantics: pending_freeze`，不得凭字面把 200 A 填入任意 COMSOL 变量。

## 5. 可执行验证方案

### 5.1 工况顺序

1. 建立机械、±300 V、±200 A 三个正向基准；
2. 为每个工况保存 MATLAB 原始输出与独立 COMSOL 证据包；
3. 完成 0.5 mm 和 1.0 mm 位移的反向电势/磁势；
4. 用两个独立求解幅值检查线性，未通过时禁止整体比例缩放；
5. 基础闭环通过后，建立平板与一个冻结曲率壳的代表性对照；
6. 先筛选主效应，再运行预指定曲率×梯度、曲率×孔隙和梯度×孔隙对比；
7. 最后才扩展完整参数面。

### 5.2 独立性证据包

每个 COMSOL 工况必须包含：模型树或等价导出；几何与坐标；材料张量分量、单位和旋转；边界条件与电/磁参考势；网格单元类型、数量和质量；求解器、容差和终止状态；指定输出坐标；未经 MATLAB 后处理的原始表格。允许共享冻结的物理规格，不允许共享 MATLAB 装配矩阵或以同一结果后处理脚本证明独立性。

### 5.3 误差预算

主相对误差为

\[
e_r=\frac{|x_{\mathrm{MATLAB}}-x_{\mathrm{COMSOL}}|}{|x_{\mathrm{COMSOL,conv}}|}\times100\%.
\]

对每条输出链预先定义特征量 `x_char`，取冻结基准工况中参考响应绝对值的最大值。当 `|x_ref| < 10^{-6}x_char` 时，不使用相对误差，改报绝对误差和 `|Δx|/x_char`；工程目标暂定为 `|Δx|/x_char ≤ 10^{-4}`。1% 是基础位移的工程调查目标，而非普遍正确性分界。0.99% 不自动正确，1.01% 也不自动错误；同时报告符号、最后两级网格变化（目标 ≤0.5%）、残差、求解状态和材料/输出口径。

### 5.4 交互与空结果路径

完整矩阵之前冻结一个主输出和三个二阶对比。交互只有在幅值高于网格变化与跨平台差异的合成上界，且分层复算保持方向一致时，才进入主要结论。若交互落在不确定度内，报告“在预设范围与数值分辨率下未检测到可分辨交互”，同时给出置信/不确定度界，不改换输出、不增删不利工况。

所有尝试工况均进入分母。失败表至少记录内存不足、非收敛、奇异矩阵、符号不一致、口径不一致和人工取消。成功率必须写成“成功数/尝试数”，不能只展示成功曲线。历史行按几何、载荷链、梯度和孔隙分层抽取至少 10% 确定性复算。

## 6. 研究边界与发表路径

没有实验样件时，结论上限是跨平台数值一致性、网格收敛和参数敏感性。两个求解器可能共享相同理想化本构，因此不能把接近结果写成物理真实。微/纳板文献只用于主题边界，不参与宏观板壳的效应量合并。

若五条基础链路闭合且交互可分辨，结果型论文可聚焦曲率--梯度--孔隙的设计窗口；若交互为空但误差边界稳定，则聚焦可重复数值验证；若基础链路仍超标，则论文应聚焦材料/边界/输出接口的失败诊断，暂不进入大规模参数研究。这三条路径均在运行前冻结，防止移动目标。

## 7. 结论

后续处理不是可选附加，而是小论文成立的证据前提。优先级不是立即运行 629 个工况，而是先闭合 ±300 V、±200 A 和反向电/磁势，证明 COMSOL 独立性，冻结磁载荷语义与曲壳输出点，再扩展曲率、梯度和孔隙。基础闭环未过门槛时，大规模扫参只会放大不确定性。

本阶段最重要的结果是把创新与验证边界固定下来：FG-MEE 板壳、曲率、多孔与双向耦合本身已有前人研究；可争取的贡献是三路独立数值一致性、可复核误差/失败审计，以及预指定交互或有界空结果。所有结论保持数值研究范围，不升级为实验验证。

## 参考文献

Brischetto, S., Cesare, D., & Mondino, T. (2025). 3D exact magneto-electro-elastic static analysis of multilayered plates. *Computer Modeling in Engineering & Sciences, 144*(1), 643–668. https://doi.org/10.32604/cmes.2025.066313 <!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->

Ellouz, H., Jrad, H., Wali, M., & Dammak, F. (2023). Numerical modeling of geometrically nonlinear responses of smart magneto-electro-elastic functionally graded double curved shallow shells based on improved FSDT. *Computers & Mathematics with Applications, 151*, 271–287. https://doi.org/10.1016/j.camwa.2023.09.040 <!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->

Gong, Z., Zhang, Y., Du, C., Pan, E., & Zhang, C. (2025). A general magneto-electro-elastic 3D FE model for free vibration and dynamic responses of multiphase composites. *Thin-Walled Structures, 213*, 113242. https://doi.org/10.1016/j.tws.2025.113242 <!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->

Nan, C.-W., Bichurin, M. I., Dong, S., Viehland, D., & Srinivasan, G. (2008). Multiferroic magnetoelectric composites: Historical perspective, status, and future directions. *Journal of Applied Physics, 103*(3), 031101. https://doi.org/10.1063/1.2836410 <!--ref:nan2008_review--><!--anchor:section:Abstract-->

Tarkashvand, A., Zafari, H., & Aliakbari, F. (2025). Novel multi-physics simulation of transient dynamics in functionally graded porous multiferroic cylindrical shells under moving heat flux. *Engineering Structures, 322*, 119116. https://doi.org/10.1016/j.engstruct.2024.119116 <!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract-->

Tassi, N., Bakkali, A., Fakri, N., Azrar, L., & Aljinaidi, A. (2022). Mathematical modeling of fully coupled reinforced magneto-electro-thermo-mechanical effective properties based on conditioned micromechanics. *Composite Structures, 280*, 114896. https://doi.org/10.1016/j.compstruct.2021.114896 <!--ref:tassi2022_effective--><!--anchor:section:Abstract-->

Vinyas, M., & Kattimani, S. C. (2018). Investigation of the effect of BaTiO3/CoFe2O4 particle arrangement on the static response of magneto-electro-thermo-elastic plates. *Composite Structures, 185*, 51–64. https://doi.org/10.1016/j.compstruct.2017.10.073 <!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract-->

Zhang, S.-Q., Qian, S.-Y., Liu, S., Ling, C.-Y., & Ma, S.-Y. (2026). Fully coupled modeling for static and dynamic analysis of thermo-magneto-electro-elastic plates. *International Journal of Mechanics and Materials in Design, 22*(1), Article 17. https://doi.org/10.1007/s10999-025-09834-9 <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5-->

Zhang, S.-Q., Zhao, Y.-F., Wang, X., Chen, M., & Schmidt, R. (2022). Static and dynamic analysis of functionally graded magneto-electro-elastic plates and shells. *Composite Structures, 281*, 114950. https://doi.org/10.1016/j.compstruct.2021.114950 <!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract-->

Zhao, Y.-F., Gao, Y.-S., Wang, X., Markert, B., & Zhang, S.-Q. (2024). Finite element analysis of functionally graded magneto-electro-elastic porous cylindrical shells subjected to thermal loads. *Mechanics of Advanced Materials and Structures, 31*(17), 4003–4018. https://doi.org/10.1080/15376494.2023.2188326 <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->

赵亚飞. (2023). *磁电弹梯度结构多物理场耦合非线性建模与分析* [博士学位论文，上海大学]. <!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->

## AI、利益冲突与可用性披露

**AI Disclosure.** This report was produced with AI-assisted research tools. AI support covered literature search, metadata verification, evidence synthesis, drafting, and consistency checks. The local predecessor PDFs and quantitative claims identified in this report were checked at the stated access depth. Final scientific judgment, authorship, and submission responsibility remain with the human researcher.

**Funding.** Funding information has not yet been supplied by the researcher. No statement of “no external funding” is made until the author confirms it.

**Conflict of Interest and Contribution.** The project uses inherited/predecessor MATLAB concepts and local materials from the same research lineage. The final author list must describe code, modeling, supervision and validation contributions, and must disclose any institutional or personal conflict. No commercial conflict is currently evidenced in the available materials.

**Data and Code Availability.** Current MATLAB outputs, COMSOL logs, literature audit files and reports are stored in the private project workspace. Public release will be decided by the researcher and must respect COMSOL/MATLAB license restrictions, third-party copyright and removal of personal workstation paths. Reproducible raw tables, case passports and non-proprietary scripts should accompany submission when permitted.

**Human Subjects.** The study contains no human participants or personal data; IRB review is not applicable.

## 修订记录

| # | 来源 | 严重度 | 意见 | 处理 | 状态 |
|---:|---|---|---|---|---|
| 1 | Editor | Critical | 交互结果尚未完成 | 改为证据审计与验证方案；结果型标题延后 | Resolved for Stage 1 |
| 2 | Editor/DA | Major | 独立 COMSOL 未完成 | 写成下一阶段硬门槛并规定证据包 | Open experiment; no overclaim |
| 3 | Editor/DA | Major | 1% 被当作正确性分界 | 改为工程目标并增加近零、网格、符号和残差判据 | Resolved |
| 4 | DA | Major | 缺少空结果路径 | 冻结有界空结果与不移动指标的发表路径 | Resolved |
| 5 | DA | Major | 失败工况存在幸存者偏差 | 增加尝试总数和失败原因分母 | Resolved |
| 6 | Ethics | Conditional | Funding/COI 不透明 | 增加披露；Funding 保留作者确认项 | Partially resolved |
| 7 | Ethics | Conditional | 数据代码可用性未写 | 增加可用性与许可边界 | Resolved |
| 8 | Ethics | Conditional | 撤稿/更正状态未查 | 列为投稿前强制核查 | Open pre-submission |
| 9 | Editor | Major | 五篇直接竞争文献全文不足 | 列为创新定稿前强制获取 | Open literature task |

## 尚未解决事项

1. 作者确认经费来源、利益冲突和贡献分工。
2. 投稿前系统核查引用论文的撤稿、更正或关注声明。
3. 获取并阅读全文核查 5 篇最相近竞争论文。
4. 执行独立 ±300 V、±200 A、反向电/磁势和代表曲率工况。

