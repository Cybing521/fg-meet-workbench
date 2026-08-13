# 注释书目

> 使用说明：除 Zhang et al. (2026) 和 Zhao (2023) 外，以下注释主要依据 DOI 元数据、出版社页面、题名和摘要，目的在于限定研究范围而非替代全文精读。证据等级采用工程数值研究口径；Level VI 表示个体计算/理论研究，并非质量差。

## 1. 核心基准与直接前人工作

### Zhang, Qian, Liu, Ling, and Ma (2026) — `zhang2026_full`

Zhang, S.-Q., Qian, S.-Y., Liu, S., Ling, C.-Y., & Ma, S.-Y. (2026). Fully coupled modeling for static and dynamic analysis of thermo-magneto-electro-elastic plates. *International Journal of Mechanics and Materials in Design, 22*(1), Article 17. https://doi.org/10.1007/s10999-025-09834-9

- 相关性：本项目机械、电、磁加载位移验证的首要定量基准。
- 方法与发现：原始 PDF 显示其全耦合板模型与 COMSOL 对照；CFFF 中心点 ±300 V 位移约为 -5.23×10^-2 mm，±200 A 位移为 1.75×10^-1 mm（COMSOL 1.73×10^-1 mm）。
- 质量：Level VI，A；全文和出版页面均已核验。
- 限制：本项目程序知识链与前人工作有关，同源代码复跑不能替代独立 COMSOL 验证。

### Zhao, Gao, Wang, Markert, and Zhang (2024) — `zhao2024_porous_shell`

Zhao, Y.-F., Gao, Y.-S., Wang, X., Markert, B., & Zhang, S.-Q. (2024). Finite element analysis of functionally graded magneto-electro-elastic porous cylindrical shells subjected to thermal loads. *Mechanics of Advanced Materials and Structures, 31*(17), 4003–4018. https://doi.org/10.1080/15376494.2023.2188326

- 相关性：直接覆盖多孔 FG-MEE 圆柱壳，是“多孔曲壳首次研究”主张的反证。
- 方法与发现：题名和正式摘要表明其采用有限元研究热载荷下的功能梯度多孔磁电弹圆柱壳。
- 质量：Level VI，A；DOI、OpenAlex、Crossref 和出版社页面一致。
- 限制：本轮未逐页核对全文，具体参数和数值不能直接移入本项目。

### Zhang, Zhao, Wang, Chen, and Schmidt (2022) — `zhang2022_fgmee_shell`

Zhang, S.-Q., Zhao, Y.-F., Wang, X., Chen, M., & Schmidt, R. (2022). Static and dynamic analysis of functionally graded magneto-electro-elastic plates and shells. *Composite Structures, 281*, 114950. https://doi.org/10.1016/j.compstruct.2021.114950

- 相关性：直接确立 FG-MEE 板壳静、动态研究已经存在。
- 方法与发现：研究范围同时包含板和壳及功能梯度磁电弹耦合，是当前模型和创新边界的重要上游来源。
- 质量：Level VI，A；多源元数据与出版页面核验通过。
- 限制：需取得全文后才能逐项确认边界、输出点和材料张量口径。

### Zhao (2023) — `zhao2023_dissertation`

赵亚飞. (2023). *磁电弹梯度结构多物理场耦合非线性建模与分析* [博士学位论文，上海大学].

- 相关性：最关键的本地前人证据，涵盖平板/曲壳、梯度、孔隙、热载荷以及电势和磁势输出。
- 方法与发现：原始 PDF 关键页显示其设置多组曲率、±200 V、厚度方向输出，并在后续章节研究多孔 FG-MEEP 圆柱壳。
- 质量：Level VI，A-；原始全文可视核验，但不是期刊同行评审来源。
- 限制：其广泛覆盖意味着本论文必须以独立验证和交互规律收窄创新，而不能只做工况复现。

## 2. 曲率、非线性与壳体扩展

### Gan and She (2024) — `gan2024_imperfect_shell`

Gan, L.-L., & She, G.-L. (2024). Nonlinear transient response of magneto-electro-elastic cylindrical shells with initial geometric imperfection. *Applied Mathematical Modelling, 132*, 166–186. https://doi.org/10.1016/j.apm.2024.04.049

- 相关性：说明 MEE 圆柱壳的几何缺陷和非线性瞬态效应已有专门研究。
- 方法与发现：正式摘要范围聚焦初始几何缺陷对圆柱壳瞬态响应的影响。
- 质量：Level VI，A。
- 限制：与本项目理想几何静力基线不同，只用于界定扩展方向。

### Pham Hoang Tu et al. (2024) — `tran2024_double_curved`

Pham Hoang Tu, Tran Van Ke, Vu Khac Trai, & Le Hoai. (2024). An isogeometric analysis approach for dynamic response of doubly-curved magneto electro elastic composite shallow shell subjected to blast loading. *Defence Technology, 41*, 159–180. https://doi.org/10.1016/j.dt.2024.06.005

- 相关性：证明双曲 MEE 浅壳和等几何分析已进入动态冲击问题。
- 方法与发现：题名与出版社页面表明其研究爆炸载荷下双曲 MEE 复合浅壳动态响应。
- 质量：Level VI，A。
- 限制：动态冲击与静态致动输出不可直接进行误差比较。

### Ellouz et al. (2023) — `belbachir2023_double_curved`

Ellouz, H., Jrad, H., Wali, M., & Dammak, F. (2023). Numerical modeling of geometrically nonlinear responses of smart magneto-electro-elastic functionally graded double curved shallow shells based on improved FSDT. *Computers & Mathematics with Applications, 151*, 271–287. https://doi.org/10.1016/j.camwa.2023.09.040

- 相关性：直接覆盖 FG-MEE 双曲浅壳和几何非线性，进一步压缩宽泛曲率创新空间。
- 方法与发现：采用改进一阶剪切变形理论进行数值建模。
- 质量：Level VI，A。
- 限制：理论阶次与本项目离散形式需统一后方可比较。

### Tarkashvand, Zafari, and Aliakbari (2025) — `tarkashvand2025_moving_heat`

Tarkashvand, A., Zafari, H., & Aliakbari, F. (2025). Novel multi-physics simulation of transient dynamics in functionally graded porous multiferroic cylindrical shells under moving heat flux: A magneto-electro-thermoelastic analysis. *Engineering Structures, 322*, 119116. https://doi.org/10.1016/j.engstruct.2024.119116

- 相关性：同时连接功能梯度、孔隙、多铁圆柱壳和磁电热弹瞬态耦合。
- 方法与发现：正式摘要范围为移动热流作用下多孔圆柱壳的多物理场瞬态模拟。
- 质量：Level VI，A。
- 限制：移动热源不是当前小论文主工况，主要用于创新边界。

## 3. 多孔、微纳尺度与优化研究

### Zhao et al. (2022) — `zhao2022_cntmee`

Zhao, Y.-F., Zhang, S.-Q., Wang, X., Ma, S.-Y., Zhao, G.-Z., & Kang, Z. (2022). Nonlinear analysis of carbon nanotube reinforced functionally graded plates with magneto-electro-elastic multiphase matrix. *Composite Structures, 297*, 115969. https://doi.org/10.1016/j.compstruct.2022.115969

- 相关性：提示 MEE 多相基体、CNT 增强和 FG 板非线性已形成组合研究。
- 方法与发现：研究对象为 CNT 增强功能梯度板及磁电弹多相基体。
- 质量：Level VI，B+。
- 限制：CNT 增强材料体系与本研究 BaTiO3/CoFe2O4 梯度体系不同。

### Koç, Esen, and Eroğlu (2024) — `koc2024_porous_core`

Koç, M. A., Esen, İ., & Eroğlu, M. (2024). Thermomechanical vibration response of nanoplates with magneto-electro-elastic face layers and functionally graded porous core using nonlocal strain gradient elasticity. *Mechanics of Advanced Materials and Structures, 31*(18), 4477–4509. https://doi.org/10.1080/15376494.2023.2199412

- 相关性：展示 MEE 面层、FG 多孔芯层与尺度效应的组合。
- 方法与发现：采用非局部应变梯度理论分析纳米板热机振动。
- 质量：Level VI，B；OpenAlex 和出版社页面核验通过。
- 限制：Crossref 本轮限流；纳米尺度不能直接约束宏观板壳数值。

### Esen, Aktaş, and Pehlivan (2025) — `esen2025_porous_nanoplate`

Esen, İ., Aktaş, K. G., & Pehlivan, F. (2025). Investigation of the critical buckling temperatures and free vibration response of porous functionally graded magneto-electro-elastic sandwich higher-order nanoplates with temperature-dependent material properties. *Journal of Vibration Engineering & Technologies, 13*(2), Article 162. https://doi.org/10.1007/s42417-024-01542-6

- 相关性：说明多孔 FG-MEE 夹层板、温变材料和高阶尺度模型已有研究。
- 方法与发现：研究临界屈曲温度与自由振动响应。
- 质量：Level VI，B+。
- 限制：并非本项目静力宏观板壳基准。

### Kar and Srinivas (2025) — `kar2025_porous_microplate`

Kar, U. K., & Srinivas, J. (2025). Dynamic analysis and structural optimization study of porous FG-MEE microplate with impact and hygrothermal loads. *Proceedings of the Institution of Mechanical Engineers, Part C, 239*(8), 2971–2993. https://doi.org/10.1177/09544062241299210

- 相关性：将多孔 FG-MEE 微板扩展到冲击、湿热和优化，说明“参数优化”本身也不能自动视为创新。
- 方法与发现：正式摘要范围为动态分析和结构优化。
- 质量：Level VI，B+。
- 限制：微尺度、冲击与湿热效应均超出当前验证主线。

### Özmen (2023) — `ozmen2023_nanoplates`

Özmen, R. (2023). Thermomechanical vibration and buckling response of magneto-electro-elastic higher order laminated nanoplates. *Applied Mathematical Modelling, 122*, 373–400. https://doi.org/10.1016/j.apm.2023.06.005

- 相关性：提供高阶层合 MEE 纳米板的热机振动与屈曲方法边界。
- 方法与发现：研究高阶层合纳米板的热机振动和屈曲。
- 质量：Level VI，B。
- 限制：尺度效应和动力学指标不用于当前静态绝对值验证。

## 4. 三维方法、材料参数与计算基准

### Brischetto, Cesare, and Mondino (2025) — `brischetto2025_3d`

Brischetto, S., Cesare, D., & Mondino, T. (2025). 3D exact magneto-electro-elastic static analysis of multilayered plates. *Computer Modeling in Engineering & Sciences, 144*(1), 643–668. https://doi.org/10.32604/cmes.2025.066313

- 相关性：提供多层 MEE 板三维精确静力解，可用于评估低阶板理论误差。
- 方法与发现：研究多层板的三维精确磁电弹静力分析。
- 质量：Level VI，A。
- 限制：需先统一材料层序、边界和无量纲化才能成为定量基准。

### Gong et al. (2025) — `gong2025_comsol3d`

Gong, Z., Zhang, Y., Du, C., Pan, E., & Zhang, C. (2025). A general magneto-electro-elastic 3D FE model for free vibration and dynamic responses of multiphase composites. *Thin-Walled Structures, 213*, 113242. https://doi.org/10.1016/j.tws.2025.113242

- 相关性：为通用三维 MEE 有限元和 COMSOL 对照提供近期方法证据。
- 方法与发现：聚焦多相复合材料的自由振动和动力响应。
- 质量：Level VI，A。
- 限制：当前论文主线为静态验证，不能直接采用其动态误差阈值。

### Zhou and Qu (2023) — `zhou2023_migam`

Zhou, L., & Qu, F. (2023). The magneto-electro-elastic coupling isogeometric analysis method for the static and dynamic analysis of magneto-electro-elastic structures under thermal loading. *Composite Structures, 315*, 116984. https://doi.org/10.1016/j.compstruct.2023.116984

- 相关性：提供热载荷下 MEE 静动态等几何耦合方法。
- 方法与发现：建立 MEE 耦合等几何分析框架。
- 质量：Level VI，A。
- 限制：不同离散技术之间应比较收敛量和统一输出，而非只比较图形趋势。

### Tassi et al. (2022) — `tassi2022_effective`

Tassi, N., Bakkali, A., Fakri, N., Azrar, L., & Aljinaidi, A. (2022). Mathematical modeling of fully coupled reinforced magneto-electro-thermo-mechanical effective properties based on conditioned micromechanics. *Composite Structures, 280*, 114896. https://doi.org/10.1016/j.compstruct.2021.114896

- 相关性：直接约束全耦合有效材料参数如何从微观组分转换到宏观模型。
- 方法与发现：采用条件化微观力学构建增强型磁电热机有效性质。
- 质量：Level VI，A。
- 限制：其均匀化规则必须与本项目材料参数转换程序逐项映射。

### Zhou et al. (2022) — `zhou2022_enriched`

Zhou, L., Wang, J., Liu, M., Li, M., & Chai, Y. (2022). Evaluation of the transient performance of magneto-electro-elastic based structures with the enriched finite element method. *Composite Structures, 280*, 114888. https://doi.org/10.1016/j.compstruct.2021.114888

- 相关性：提供富集有限元处理 MEE 结构瞬态响应的方法对照。
- 方法与发现：评价 MEE 结构的瞬态性能。
- 质量：Level VI，A-。
- 限制：不提供当前静态板壳的直接工况基准。

### Vinyas and Kattimani (2018) — `vinyas2018_arrangement`

Vinyas, M., & Kattimani, S. C. (2018). Investigation of the effect of BaTiO3/CoFe2O4 particle arrangement on the static response of magneto-electro-thermo-elastic plates. *Composite Structures, 185*, 51–64. https://doi.org/10.1016/j.compstruct.2017.10.073

- 相关性：与本项目常用 BaTiO3/CoFe2O4 组分直接相关，可解释组分排列对静态响应的影响。
- 方法与发现：研究不同颗粒排列下磁电热弹板静态响应。
- 质量：Level VI，A-。
- 限制：颗粒排列与连续厚度功能梯度不是同一参数化方式。

## 5. 经典方法与材料基础

### Sladek et al. (2013) — `sladek2013_large_deflection`

Sladek, J., Sladek, V., Krahulec, S., & Pan, E. (2013). The MLPG analyses of large deflections of magnetoelectroelastic plates. *Engineering Analysis with Boundary Elements, 37*(4), 673–682. https://doi.org/10.1016/j.enganabound.2013.02.001

- 相关性：提供 MEE 板大挠度和无网格局部 Petrov–Galerkin 方法的经典证据。
- 方法与发现：研究几何大挠度下磁电弹板响应。
- 质量：Level VI，B+。
- 限制：年代较早且数值方法不同，主要用于理论脉络。

### Kondaiah, Shankar, and Ganesan (2012) — `kondaiah2012_cantilever`

Kondaiah, P., Shankar, K., & Ganesan, N. (2012). Studies on magneto-electro-elastic cantilever beam under thermal environment. *Coupled Systems Mechanics, 1*(2), 205–217. https://doi.org/10.12989/csm.2012.1.2.205

- 相关性：提供热环境下 MEE 悬臂结构的早期可复核算例。
- 方法与发现：研究悬臂梁热-机-电-磁耦合响应。
- 质量：Level VI，B。
- 限制：梁模型不能替代二维板壳验证。

### Dat, Quan, and Duc (2022) — `dat2022_auxetic`

Dat, N. D., Quan, T. Q., & Duc, N. D. (2022). Vibration analysis of auxetic laminated plate with magneto-electro-elastic face sheets subjected to blast loading. *Composite Structures, 280*, 114925. https://doi.org/10.1016/j.compstruct.2021.114925

- 相关性：展示负泊松层合板、MEE 面层与爆炸载荷的组合建模。
- 方法与发现：聚焦动态振动响应。
- 质量：Level VI，B+。
- 限制：属于相邻结构证据，不用于本项目静态阈值。

### Nan et al. (2008) — `nan2008_review`

Nan, C.-W., Bichurin, M. I., Dong, S., Viehland, D., & Srinivasan, G. (2008). Multiferroic magnetoelectric composites: Historical perspective, status, and future directions. *Journal of Applied Physics, 103*(3), 031101. https://doi.org/10.1063/1.2836410

- 相关性：提供多铁磁电复合材料的历史、机制和材料层基础。
- 方法与发现：综述磁电复合材料的发展与方向，不是板壳求解论文。
- 质量：Level VII，A，作为基础综述保留。
- 限制：不能支持具体位移、电势或磁势数值。

## 6. 书目层面的综合判断

23 条来源中，直接限制创新主张的核心来源是 Zhao (2023)、Zhang et al. (2022)、Zhao et al. (2024)、Ellouz et al. (2023) 和 Tarkashvand et al. (2025)；直接支撑数值验证设计的是 Zhang et al. (2026)、Brischetto et al. (2025)、Gong et al. (2025)、Zhou and Qu (2023) 以及 Tassi et al. (2022)。因此，后续论文应以“独立三路验证 + 同口径曲率/梯度/孔隙交互”为主线，而非罗列更多已存在的结构类型。

