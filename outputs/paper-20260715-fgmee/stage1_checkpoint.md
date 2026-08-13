# Stage 1（RESEARCH）完成检查点

## 阶段结论

Stage 1 已完成从研究问题、文献调查、来源核验、证据综合、完整报告、三路审稿到修订版报告的全流程。自动引用检查、材料护照 schema 和阶段范围完整性检查均通过。

## 已证明

- 机械力--位移已有代表性独立 MATLAB--COMSOL 基线，误差为 0.710707%。
- 22 篇 DOI 论文的来源身份均已核验；23 条结构化来源通过 schema。
- FG-MEE 板壳、曲率、多孔圆柱壳和双向场输出已有前人覆盖，宽泛“对象首次”创新不成立。
- 论文可保留的主线是独立三路数值一致性，以及预指定的曲率×梯度×孔隙交互或有界空结果。

## 尚未证明（下一阶段必须执行）

1. ±300 V 电致位移的本项目独立 COMSOL 证据包；
2. ±200 A 磁致位移的精确载荷语义与独立 COMSOL 证据包；
3. 0.5/1.0 mm 位移反演电势与磁势的独立验证；
4. 曲壳输出点冻结和代表工况闭环；
5. 曲率×梯度×孔隙交互是否高于合成数值不确定度；
6. 五篇最相近竞争文献的全文核查；
7. 作者确认 Funding、COI、贡献分工和公开数据/代码范围。

## 审稿结论

- Editor-in-Chief：Major Revision。原因是结果型贡献尚未由新仿真支撑；已将本阶段文档改为“证据审计与验证方案”。
- Ethics：Conditional。无伦理阻断；Funding/COI、数据代码可用性与投稿前撤稿/更正核查需补齐。
- Devil's Advocate：Revise。要求保留空结果路径、全部尝试工况分母，并把 1% 作为工程目标而非正确性分界。

## Stage 2 建议入口

进入 Stage 2 后先执行实验闭环，不直接写完成态小论文：

1. 冻结三组正向加载的 case passport；
2. 运行 ±300 V 与 ±200 A 独立 COMSOL；
3. 运行反向感知；
4. 通过数值门槛后运行一个代表曲率工况；
5. 再进行分层主效应/交互矩阵；
6. 将新数据写入 LaTeX 小论文并编译 PDF。

## 检查状态

| 检查 | 结果 |
|---|---|
| 三层引用 lint | PASS（3 个叙事文件，0 裸引用，0 none 定位） |
| Pipeline phase-scope integrity | PASS（0 findings） |
| Claim intent manifest schema | PASS（3/3） |
| Experiment provenance schema | PASS（2/2） |
| Literature corpus schema | PASS（23/23） |

