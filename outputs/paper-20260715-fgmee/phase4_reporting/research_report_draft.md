# 经独立数值验证的多孔功能梯度磁电弹板壳双向耦合：研究证据、创新边界与实施方案

**研究阶段报告（完整模式，初稿）**

日期：2026-07-15  
研究对象：含孔隙功能梯度磁电弹（FG-MEE/FG-MEEP）板壳  
报告性质：研究问题、证据基础与后续数值实验方案；不将尚未执行的实验写为结果

## 摘要

本报告评估一项 FG-MEE 板壳小论文计划的证据充分性、创新边界和数值验证路径。研究首先审计现有 MATLAB、COMSOL 与前人文献材料，再对 31 条候选记录进行定向筛选，纳入 22 篇期刊论文和 1 篇博士论文。证据显示，功能梯度磁电弹板壳、曲率、多孔圆柱壳、双向机--电--磁响应以及多类非线性扩展均已有研究，因而不能以研究对象本身主张创新。当前最可辩护的贡献是：在统一几何、材料张量、边界、载荷、坐标与输出口径下，建立 MATLAB--COMSOL--文献三路数值一致性闭环，并以预指定对比检验曲率、厚度梯度与孔隙分布的交互。现有证据已经形成机械载荷位移的独立 COMSOL 基线，但 ±300 V、±200 A 和位移反演电/磁势仍缺少全部独立闭环。报告据此冻结相对误差、近零绝对误差、网格变化、符号一致、模型独立性和交互效应门槛。研究结论的上限为跨平台数值一致性和参数敏感性；没有样件测量时，不得表述为实验或物理真实性验证。

**关键词：** 磁电弹；功能梯度；多孔板壳；曲率；COMSOL；数值验证；双向耦合

## 1. 引言

磁电弹复合结构把机械场、电场和磁场写入同一耦合本构体系。材料层研究已系统讨论多铁磁电复合材料的物理基础与发展脉络（Nan et al., 2008）<!--ref:nan2008_review--><!--anchor:section:Abstract-->。在结构层，研究对象已从梁和平板扩展到功能梯度板壳、圆柱壳、双曲浅壳和多相三维模型。早期悬臂与大挠度研究分别提供热耦合算例和非线性板分析路线（Kondaiah et al., 2012）<!--ref:kondaiah2012_cantilever--><!--anchor:section:Abstract-->、（Sladek et al., 2013）<!--ref:sladek2013_large_deflection--><!--anchor:section:Abstract-->；后续工作进一步覆盖 FG-MEE 板壳静动态分析（Zhang et al., 2022）<!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract--> 和多孔 FG-MEE 圆柱壳（Zhao et al., 2024）<!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->。

本项目的直接问题来自跨平台偏差。指导讨论指出，单纯载荷引起的位移计算在口径一致时应非常接近，而现有部分工况仍出现约 0.92% 至 2.5% 的差异；同时，2 mm 位移下的电势偏大、磁势偏小，量级合理性尚未被独立仿真确认。现有机械力--位移对照已将代表工况误差冻结为 0.710707%，但反向感知证据仍来自前人程序同工况复跑。这种证据状态要求把“结果接近”拆成三个不同命题：实现是否一致、求解器是否独立、模型是否具有物理效度。

本报告围绕以下研究问题展开：

> 在统一几何、材料、边界与输出口径下，经 MATLAB--COMSOL--文献三路验证后，曲率、厚度梯度与孔隙分布对 FG-MEE 板壳正向致动、反向感知以及跨平台数值一致性有何交互影响？

该问题包含四个可检验子问题：基础机械、电、磁加载的位移误差能否稳定低于预注册门槛；反向电势和磁势能否同时满足符号、量级和网格收敛；曲率、梯度与孔隙是否产生高于数值不确定度的非加性交互；哪些组合会放大误差或导致求解失败。

## 2. 文献综述与理论框架

### 2.1 从功能梯度板到复杂曲壳

FG-MEE 板壳并不是空白研究对象。Zhang et al. (2022) <!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract--> 已把功能梯度磁电弹板与壳纳入同一静、动态分析框架。双曲 FG-MEE 浅壳的几何非线性也已有改进剪切变形理论研究（Ellouz et al., 2023）<!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->；初始几何缺陷下的 MEE 圆柱壳瞬态非线性构成另一条扩展路线（Gan & She, 2024）<!--ref:gan2024_imperfect_shell--><!--anchor:section:Abstract-->。这些来源共同否定了“只要从平板增加翘曲就有创新”的推断。

曲率仍然具有研究价值，但价值必须来自统一口径下的比较。曲率改变膜内与弯曲响应的传递关系；如果平板与曲壳同时改变材料、边界或输出点，就无法识别差异究竟来自几何还是模型接口。赵亚飞的博士论文已在多组曲率下研究功能梯度结构，并给出沿厚度的电势和磁势输出（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->。因此，本项目必须先复现完全相同的基准工况，再定义与前人不同但可检验的交互问题。

### 2.2 孔隙、梯度与尺度边界

多孔功能梯度与 MEE 的组合也已有直接证据。Zhao et al. (2024) <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract--> 研究热载荷下多孔 FG-MEE 圆柱壳；Tarkashvand et al. (2025) <!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract--> 又把移动热流与多铁多孔圆柱壳的瞬态响应结合。微/纳尺度研究则覆盖 MEE 面层加功能梯度多孔芯（Koç et al., 2024）<!--ref:koc2024_porous_core--><!--anchor:section:Abstract--> 和多孔 FG-MEE 夹层纳米板的热屈曲及振动（Esen et al., 2025）<!--ref:esen2025_porous_nanoplate--><!--anchor:section:Abstract-->。

这些来源说明孔隙与梯度的组合并不新，但不能把微/纳板结论直接外推到宏观板壳。非局部应变梯度、尺度参数和夹层构型会改变控制方程。故本研究只用微/纳文献说明题材饱和，不用其绝对数值选择宏观参数范围，也不把跨尺度文献数量当作宏观效应强度证据。

### 2.3 跨方法验证与材料接口

本项目最直接的数值基准来自 Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5-->。原始 PDF 的对照表显示，在统一 CFFF、中心点和载荷定义下，±300 V 工况本方法与 COMSOL 的位移均约为 -5.23×10^-2 mm；±200 A 工况分别约为 1.75×10^-1 mm 和 1.73×10^-1 mm。这一结果支持“基础工况的跨平台差异应很小”，但不能证明任意实现都必须得到同样误差。

三维精确静力分析和通用三维有限元提供了进一步的高保真参照（Brischetto et al., 2025）<!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->、（Gong et al., 2025）<!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->。不同数值路线能够互相约束，却也可能共享同一理想化本构。因而“两个求解器接近”只能证明给定模型的跨平台一致性，不能替代实验。

材料接口是偏差诊断的重点。BaTiO3/CoFe2O4 颗粒排列会影响静态耦合响应（Vinyas & Kattimani, 2018）<!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract-->，而全耦合有效性质可由特定微观力学规则构造（Tassi et al., 2022）<!--ref:tassi2022_effective--><!--anchor:section:Abstract-->。所以，仅说 MATLAB 和 COMSOL 使用“相同材料参数”还不够；必须核对张量分量顺序、工程剪切与张量剪切、电/磁耦合项符号、极化方向、SI 单位和厚度坐标。

### 2.4 理论整合

本研究采用“接口--平衡--输出”框架。接口层冻结材料张量、坐标、单位、极化和参考势；平衡层耦合机械、静电和静磁方程，曲率影响膜--弯传递，梯度与孔隙改变厚度方向有效系数；输出层把位移、电势和磁势固定到可复核的几何/参数坐标。所有比较必须经过同一输出层，不能用不同位置的极值相互比较。

该框架还限定交互主张。曲率、梯度和孔隙同时出现在控制方程中，只能说明存在产生交互的机制可能性，不能预先证明交互显著。只有预指定二阶对比高于网格误差与跨平台差异的合成上界，并在复算中保持方向一致，才可报告为非加性效应。

## 3. 方法

### 3.1 研究设计

本阶段采用证据审计与前瞻性数值实验设计。证据审计回答“目前能证明什么、不能证明什么”；后续实验回答跨平台一致性与参数交互。两类结果分开存放，避免把研究计划写成已完成结果。

文献调查在 2026-07-15 执行，时间范围为 2008--2026，核心关注 2021--2026。检索组合包含 magneto-electro-elastic、FG-MEE、plate、shell、curvature、porosity、COMSOL、electric potential 和 magnetic potential 等词。31 条候选级记录中纳入 23 条，排除 8 个相邻但不满足 MEE 结构问题的检索结果簇。详细记录见 `phase2_literature/search_strategy.md` 与 `screening_log.csv`。

22 篇 DOI 论文通过 OpenAlex 匹配，21 篇同时通过 Crossref；1 篇因 Crossref 限流由正式出版社页面补验。Semantic Scholar 本轮服务降级，记录为 degraded 而非 unmatched。两份本地原始 PDF 完成关键页视觉核验；其余来源主要为正式摘要级证据。因此，本报告使用“本轮定向检索未见”而不使用“首次”或“尚无研究”。

### 3.2 统一工况与独立性

后续数值实验按以下顺序执行：

1. 冻结几何、厚度、层序、材料张量、边界、载荷方向、极化方向、输出点和单位；
2. 在 MATLAB 中输出原始自由度、平衡残差和指定点结果；
3. 在 COMSOL 中独立建立模型，不导入 MATLAB 装配矩阵或共享后处理代码；
4. 保存 COMSOL 模型树、材料分量映射、网格统计、求解器设置和原始表格；
5. 先完成机械压力、±300 V 和 ±200 A 三个正向工况；
6. 再完成 0.5 mm 与 1.0 mm 位移下的反向电势、磁势，并用两点独立求解检查线性；
7. 基础工况过门槛后才扩展平板/曲壳、梯度和孔隙矩阵。

“独立”指两条数值路径不共享求解矩阵和结果后处理。允许共享研究者冻结的物理规格，例如几何尺寸、材料护照和输出坐标，因为比较需要同一问题定义；不允许以同一装配程序产生的结果去证明另一实现正确。

### 3.3 误差与收敛判据

主相对误差定义为

\[
e_r=\frac{|x_{\mathrm{MATLAB}}-x_{\mathrm{COMSOL}}|}{|x_{\mathrm{COMSOL,conv}}|}\times 100\%,
\]

其中分母为完成网格收敛后的 COMSOL 指定输出。当参考量接近零时，相对误差会失稳，因此改报绝对误差并给出按预先登记特征量归一化的误差。主位移目标为不高于 1%，但通过还必须同时满足：符号一致；COMSOL 最后两级网格变化不超过 0.5%；求解器正常终止；输出点和分量完全一致。电势和磁势除上述条件外，还需核对参考势、单位与层平均/点值定义。

### 3.4 交互分析

完整矩阵不直接用于自由探索。首先在致密平板与单一基准曲率上筛选主效应；随后固定预指定二阶对比，例如“曲率效应在梯度指数高/低水平的差值”。交互效应只有在其幅值高于网格变化与 MATLAB--COMSOL 差异合成上界时才进入主要结果。历史结果至少按几何、载荷链、梯度与孔隙分层抽取 10% 进行确定性复算，不采用简单随机抽样掩盖稀有失败组合。

### 3.5 有效性措施与限制

内部有效性通过统一材料护照、工况表、输出坐标和误差公式维护；数值有效性通过网格收敛、不同求解器及文献定量对标维护；可重复性通过保存原始表格、日志、模型文件和失败记录维护。外部有效性受限于理想材料常数、边界和无实验样件。本研究不对真实器件寿命、击穿、电磁损耗或制造缺陷作未经测量的推断。

## 4. 阶段性发现

### 4.1 来源和创新边界

第一项发现是宽泛创新主张不成立。FG-MEE 板壳、曲率、多孔结构以及正反向电/磁响应都能在纳入语料中找到直接前人工作（Zhang et al., 2022）<!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract-->、（Zhao et al., 2024）<!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->、（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->。小论文不能把“计算平板和翘曲”“引入功能梯度”或“增加孔隙”单独列为创新。

第二项发现是统一三路验证仍有可辩护空间。现有文献展示多种数值模型和局部 COMSOL 对照，但本轮定向检索没有发现与本项目完全相同的五类工况、统一输出口径、失败审计和参数交互闭环。该表述是检索范围内的工作假设，不是排他性“首次”结论。

### 4.2 当前证据闭合程度

当前机械力--位移代表工况已经得到 0.710707% 的 MATLAB--COMSOL 差异，满足预设 1% 主目标。该证据来自 `outputs/manual-20260714-fgmeet-validation/latex-report/force_displacement_validation_20260714.tex`，可作为机械基线。

电、磁正向工况已与 Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 的表格进行对照，现有差异约为 0.08%--0.92%，但尚缺本项目独立 COMSOL 原始模型包。位移反演电势/磁势的前人程序同工况复跑达到约 10^-12 的实现差异，只能证明两次程序输出一致，不能证明物理公式、单位和 COMSOL 场变量正确。故三条待办仍为必要内容，而不是可选美化。

### 4.3 数值合理性风险

指导讨论指出，2 mm 位移下上万伏电势和约 0.6 的磁势可能不合理。现有文献证据只能提供同工况量级约束，不能在位移、边界和势参考不同的情况下直接判错。赵亚飞的论文显示输出势会随曲率、梯度、边界和层位置变化（Zhao, 2023）<!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->。因此，后续先复现前人的完全相同工况，再求解 0.5 mm 和 1.0 mm 两个位移；只有确认线性后，才允许用比例缩放解释其他幅值。

### 4.4 计划贡献的条件状态

当前能够成立的贡献是研究设计贡献：统一输入/输出口径、把独立性写成证据包、预注册误差和交互门槛、保留失败案例。尚不能成立的结果贡献是“发现曲率--梯度--孔隙的非加性交互”。如果后续交互低于合成数值不确定度，论文应转为跨平台验证与可重复性论文，而不是事后更换指标寻找显著曲线。

## 5. 讨论

### 5.1 为什么 2% 在基础工况中仍值得追查

相对误差是否“大”取决于问题类型和参考量。复杂非线性、多孔三维或热耦合问题可能出现更高方法差异；但在材料、边界和输出完全一致的基础线性位移工况中，Zhang et al. (2026) <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5--> 的表格显示差异很小。因而 2% 不是证明模型错误的充分条件，却足以触发接口审计。最可能的诊断顺序是单位和符号、材料张量映射、边界自由度、载荷面积/方向、输出点、网格与求解器。

### 5.2 数值一致性与正确性的区别

跨平台一致性可以发现实现错误，但不能证明本构假设真实。两个模型如果使用同一理想材料常数、忽略相同损耗或共享错误的极化方向，仍可能高度一致。三维模型和精确解能增强离散层面的可信度（Brischetto et al., 2025）<!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->，但物理有效性最终需要实验测量。小论文若暂时无法做实验，应把范围明确限定为数值研究，不以“实际合理”替代“同工况量级一致”。

### 5.3 小论文的可发表叙事

可发表叙事应按证据强度排序。第一层是机械、电、磁正向加载的独立跨平台闭环；第二层是反向电/磁势的同工况量级与符号验证；第三层才是平板/曲壳和梯度/孔隙交互。这样安排使后续创新结果建立在可信基础上，也允许在第三层没有明显交互时保留前两层的验证价值。

最强的反方意见是：这只是成熟模型的工程复算。回应该意见不能依赖增加工况数量，而要展示前人研究未清楚提供的可审计独立性、失败边界和同口径交互。如果后续没有超出数值误差的交互或设计窗口，就应主动承认论文贡献主要是复现与验证。

### 5.4 实施优先级

下一步首先完成 ±300 V 和 ±200 A 的独立 COMSOL 正向工况。它们直接对应已核原始表格，可最快判断材料张量、边界和单位是否正确。随后处理位移反向感知；磁势若无法在 COMSOL 物理接口中同构实现，应使用用户定义 PDE 或明确降级证据，而不是把非同构模型写成直接验证。基础工况全部闭合后，再选择一个曲率壳完成代表性对照，最后开展分层参数矩阵。

## 6. 结论

本阶段已经回答“后续内容是否必要”：必要，但不是所有 629 个工况都应立即运行。必要的硬前置包括 ±300 V、±200 A 和反向感知的独立验证，材料/坐标/输出口径冻结，曲壳中心点定义，以及网格和失败审计。曲率、梯度与孔隙的完整扩展只有在基础闭环通过后才有解释价值。

文献证据同时修正了论文定位。FG-MEE 板壳、曲率、多孔和双向耦合均不是新的研究对象。最可辩护的路线是以跨平台一致性为基础，用预指定对比检验曲率--梯度--孔隙是否产生高于数值不确定度的交互。如果产生稳定交互，则形成设计规律贡献；如果没有，则形成严格的验证与可重复性结果。两种结果都应如实报告，不移动目标。

## 参考文献

Brischetto, S., Cesare, D., & Mondino, T. (2025). 3D exact magneto-electro-elastic static analysis of multilayered plates. *Computer Modeling in Engineering & Sciences, 144*(1), 643–668. https://doi.org/10.32604/cmes.2025.066313 <!--ref:brischetto2025_3d--><!--anchor:section:Abstract-->

Ellouz, H., Jrad, H., Wali, M., & Dammak, F. (2023). Numerical modeling of geometrically nonlinear responses of smart magneto-electro-elastic functionally graded double curved shallow shells based on improved FSDT. *Computers & Mathematics with Applications, 151*, 271–287. https://doi.org/10.1016/j.camwa.2023.09.040 <!--ref:belbachir2023_double_curved--><!--anchor:section:Abstract-->

Esen, İ., Aktaş, K. G., & Pehlivan, F. (2025). Investigation of the critical buckling temperatures and free vibration response of porous functionally graded magneto-electro-elastic sandwich higher-order nanoplates with temperature-dependent material properties. *Journal of Vibration Engineering & Technologies, 13*(2), Article 162. https://doi.org/10.1007/s42417-024-01542-6 <!--ref:esen2025_porous_nanoplate--><!--anchor:section:Abstract-->

Gan, L.-L., & She, G.-L. (2024). Nonlinear transient response of magneto-electro-elastic cylindrical shells with initial geometric imperfection. *Applied Mathematical Modelling, 132*, 166–186. https://doi.org/10.1016/j.apm.2024.04.049 <!--ref:gan2024_imperfect_shell--><!--anchor:section:Abstract-->

Gong, Z., Zhang, Y., Du, C., Pan, E., & Zhang, C. (2025). A general magneto-electro-elastic 3D FE model for free vibration and dynamic responses of multiphase composites. *Thin-Walled Structures, 213*, 113242. https://doi.org/10.1016/j.tws.2025.113242 <!--ref:gong2025_comsol3d--><!--anchor:section:Abstract-->

Kondaiah, P., Shankar, K., & Ganesan, N. (2012). Studies on magneto-electro-elastic cantilever beam under thermal environment. *Coupled Systems Mechanics, 1*(2), 205–217. https://doi.org/10.12989/csm.2012.1.2.205 <!--ref:kondaiah2012_cantilever--><!--anchor:section:Abstract-->

Koç, M. A., Esen, İ., & Eroğlu, M. (2024). Thermomechanical vibration response of nanoplates with magneto-electro-elastic face layers and functionally graded porous core using nonlocal strain gradient elasticity. *Mechanics of Advanced Materials and Structures, 31*(18), 4477–4509. https://doi.org/10.1080/15376494.2023.2199412 <!--ref:koc2024_porous_core--><!--anchor:section:Abstract-->

Nan, C.-W., Bichurin, M. I., Dong, S., Viehland, D., & Srinivasan, G. (2008). Multiferroic magnetoelectric composites: Historical perspective, status, and future directions. *Journal of Applied Physics, 103*(3), 031101. https://doi.org/10.1063/1.2836410 <!--ref:nan2008_review--><!--anchor:section:Abstract-->

Sladek, J., Sladek, V., Krahulec, S., & Pan, E. (2013). The MLPG analyses of large deflections of magnetoelectroelastic plates. *Engineering Analysis with Boundary Elements, 37*(4), 673–682. https://doi.org/10.1016/j.enganabound.2013.02.001 <!--ref:sladek2013_large_deflection--><!--anchor:section:Abstract-->

Tarkashvand, A., Zafari, H., & Aliakbari, F. (2025). Novel multi-physics simulation of transient dynamics in functionally graded porous multiferroic cylindrical shells under moving heat flux: A magneto-electro-thermoelastic analysis. *Engineering Structures, 322*, 119116. https://doi.org/10.1016/j.engstruct.2024.119116 <!--ref:tarkashvand2025_moving_heat--><!--anchor:section:Abstract-->

Tassi, N., Bakkali, A., Fakri, N., Azrar, L., & Aljinaidi, A. (2022). Mathematical modeling of fully coupled reinforced magneto-electro-thermo-mechanical effective properties based on conditioned micromechanics. *Composite Structures, 280*, 114896. https://doi.org/10.1016/j.compstruct.2021.114896 <!--ref:tassi2022_effective--><!--anchor:section:Abstract-->

Vinyas, M., & Kattimani, S. C. (2018). Investigation of the effect of BaTiO3/CoFe2O4 particle arrangement on the static response of magneto-electro-thermo-elastic plates. *Composite Structures, 185*, 51–64. https://doi.org/10.1016/j.compstruct.2017.10.073 <!--ref:vinyas2018_arrangement--><!--anchor:section:Abstract-->

Zhang, S.-Q., Qian, S.-Y., Liu, S., Ling, C.-Y., & Ma, S.-Y. (2026). Fully coupled modeling for static and dynamic analysis of thermo-magneto-electro-elastic plates. *International Journal of Mechanics and Materials in Design, 22*(1), Article 17. https://doi.org/10.1007/s10999-025-09834-9 <!--ref:zhang2026_full--><!--anchor:section:Tables_4-5-->

Zhang, S.-Q., Zhao, Y.-F., Wang, X., Chen, M., & Schmidt, R. (2022). Static and dynamic analysis of functionally graded magneto-electro-elastic plates and shells. *Composite Structures, 281*, 114950. https://doi.org/10.1016/j.compstruct.2021.114950 <!--ref:zhang2022_fgmee_shell--><!--anchor:section:Abstract-->

Zhao, Y.-F., Gao, Y.-S., Wang, X., Markert, B., & Zhang, S.-Q. (2024). Finite element analysis of functionally graded magneto-electro-elastic porous cylindrical shells subjected to thermal loads. *Mechanics of Advanced Materials and Structures, 31*(17), 4003–4018. https://doi.org/10.1080/15376494.2023.2188326 <!--ref:zhao2024_porous_shell--><!--anchor:section:Abstract-->

赵亚飞. (2023). *磁电弹梯度结构多物理场耦合非线性建模与分析* [博士学位论文，上海大学]. <!--ref:zhao2023_dissertation--><!--anchor:page:95-102-->

## AI 使用披露

AI Disclosure: This report was produced with AI-assisted research tools. The research pipeline included AI-powered literature search, source verification, evidence synthesis, and report drafting. Source identity and key local-PDF claims were checked against the cited evidence. Human oversight and final scientific responsibility remain with the researcher.

## 未解决问题

1. 五篇最相近竞争论文仍需取得全文并核查方法和结果细节。
2. ±300 V、±200 A 与反向感知的独立 COMSOL 证据包尚未运行。
3. 曲率--梯度--孔隙交互仍是预注册假设，不是已获得结果。
4. 本研究没有实验样件证据。

**字数说明：** 本稿为完整模式中文阶段报告；按中文非空白字符计数，正文规模由随附质量检查脚本记录。

