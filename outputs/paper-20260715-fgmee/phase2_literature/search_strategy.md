# 文献调查检索策略与范围

## 1. 调查目的

本轮调查服务于如下研究问题：在统一几何、材料、边界、载荷与输出口径下，经 MATLAB--COMSOL--文献三路验证后，曲率、厚度方向功能梯度和孔隙分布如何共同影响 FG-MEE 板壳的正向致动、反向感知及数值一致性？

调查不是面向临床或政策结论的系统综述，而是面向数值研究设计的、可复核的定向证据审计。它承担三项任务：确定可靠基准；排除已经被前人覆盖的宽泛创新主张；为后续参数矩阵与验证阈值提供依据。

## 2. 数据源与检索日期

- 检索与核验日期：2026-07-15。
- 本地一手全文：钱沈云相关 2026 年论文原始 PDF、赵亚飞 2023 年博士论文原始 PDF。
- 出版商平台：SpringerLink、ScienceDirect、Taylor & Francis、SAGE、TechScience、Techno-Press。
- 元数据与 DOI 交叉核验：OpenAlex、Crossref；Semantic Scholar 已尝试，但接口在本轮持续降级，故未将其“无返回”解释为文献不成立。
- 时间窗口：2008--2026。核心窗口为 2021--2026；2008、2012、2013、2018 年文献仅作为材料基础、经典算例或方法演进证据保留。
- 语言：英文与中文。

## 3. 关键词与组合式

核心布尔式：

```text
("magneto-electro-elastic" OR "magnetoelectroelastic" OR MEE
 OR "FG-MEE" OR "FG-MEEP")
AND
(plate OR shell OR cylindrical OR curved OR "doubly-curved")
AND
("functionally graded" OR porosity OR porous OR sensor OR actuator
 OR COMSOL OR validation OR "electric potential" OR "magnetic potential")
```

扩展检索分别加入 `thermal`、`nonlinear`、`isogeometric`、`3D finite element`、`inverse sensing`、`BaTiO3/CoFe2O4` 和 `curvature`。中文检索使用“磁电弹/磁电热弹 + 功能梯度/多孔 + 板/壳 + 电势/磁势/位移”。

## 4. 纳入与排除标准

纳入标准：

1. 直接研究 MEE、FG-MEE 或 FG-MEEP 板、壳、微/纳板等结构；
2. 对正向机电磁响应、反向感知、曲率、梯度、孔隙或跨方法验证至少有一项直接贡献；
3. 具有可核验 DOI、正式出版页面，或为本地可视核验的原始学位论文；
4. 数值方法、材料配置或输出指标能够约束本研究的模型、参数或创新边界。

排除标准：

1. 仅研究压电、压磁、普通功能梯度结构而不含 MEE 耦合；
2. 仅讨论材料制备或微观磁电效应，无法约束板壳结构数值模型；
3. 仅与冲击、移动载荷或热载荷相关，但结构体系不是 MEE；
4. 重复记录、非正式聚合页、无可核验出处的二手文本；
5. 标题相关但正文问题、材料体系和输出量均与本研究不相交。

## 5. 筛选流程与计数口径

本轮建立了 31 条“候选级”筛选记录，而不是声称覆盖数据库全部原始命中：23 条来源纳入，8 条主题相邻的检索结果簇排除。23 条纳入来源包括 22 篇期刊论文和 1 篇博士论文；其中 19 条发表于 2022--2026 年，占 82.6%。该时间偏斜来自“优先核对当前方法与创新边界”的目的，较早的 4 条来源仅用于基础与经典基准。

## 6. 可重复性与限制

- DOI 候选表：`source_candidates.csv`。
- 自动核验程序：`verify_sources.py`；原始响应和核验矩阵分别为 `source_verification_raw.json`、`source_verification_matrix.csv`。
- 结构化语料：`source_corpus.json`；已按 `literature_corpus_entry.schema.json` 验证 23/23 条通过。
- 检索结果是研究设计审计，不等同于 PRISMA 系统综述；检索结果簇没有被虚构为单篇论文。
- 除两份本地原始 PDF 外，多数来源的内容判断限于 DOI 元数据、出版社页面、题名和摘要；未经全文核验的细节不得在论文中写成确定事实。

