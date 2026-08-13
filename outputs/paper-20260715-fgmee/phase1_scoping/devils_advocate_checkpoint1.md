# Devil's Advocate Report — Checkpoint 1

## Material Passport

- Origin Skill: `deep-research`
- Origin Mode: `full`
- Origin Date: `2026-07-15T10:51:58+08:00`
- Verification Status: `UNVERIFIED`
- Version Label: `research_v1`

## Verdict: PASS

### Critical Issues

No critical issues identified.

### Major Issues

1. **独立验证与同源代码复跑容易混淆**
   - Type: Evidence / Method
   - Problem: 300 V、200 A 已与论文表格对上，位移反推场量也与钱沈云代码对上，但后者不是独立 COMSOL 验证。
   - Impact: 若论文统一写成“COMSOL 验证通过”，会构成证据等级夸大。
   - Recommendation: 使用 A--D 四级证据标签；每项结论明确证据来源。

2. **曲壳输出点尚未统一**
   - Type: Construct validity
   - Problem: 现有平板包装器按 `[0.15, 0.15, 0]` 寻找最近节点，而圆柱壳中心需要按参数网格节点或壳面坐标定义。
   - Impact: 错误取点可制造虚假的曲率效应。
   - Recommendation: 扫描前先输出节点编号、参数位置和空间坐标三联表，并冻结主输出节点。

3. **创新性尚未通过文献检索证实**
   - Type: Novelty
   - Problem: 现有稿件已经研究孔隙、FG 和三类载荷；增加曲率并不自动等于创新。
   - Impact: 可能只是把两个已知参数放在同一张图上。
   - Recommendation: Phase 2 必须搜索“porous FG-MEE cylindrical shell bidirectional actuation sensing”和反例文献；若已有同类全因子研究，则把创新改为统一独立验证或曲率--梯度交互指标。

4. **范围过载风险**
   - Type: Scope
   - Problem: 静力、动力、孔隙、五种 FG、曲率、三载荷、双向传感同时作为主线会使小论文失焦。
   - Impact: 每部分验证深度不足。
   - Recommendation: 主文只保留静力三载荷验证 + 曲率--梯度--孔隙关键结果；动力与 CFCF 扫描放补充材料。

### Minor Issues

- “翘曲”需在论文中统一为“初始曲率圆柱壳”或真正的“翘曲变形”，避免术语混用。
- 300 V 与 ±300 V、200 A 与 ±200 A 的“幅值/跨度”必须固定写法。
- 小位移点不宜只报相对误差，应同时给绝对误差。

### Strongest Counter-Argument

“所观察到的孔隙、梯度和曲率趋势只是既定混合律导致的刚度缩放，并未揭示新的耦合机制；同时 COMSOL 的等效场模型与 MATLAB 全耦合矩阵并不完全同构，因此所谓跨软件验证和曲率交互结论可能只是模型口径差异。”

### What's Missing

- 独立电/磁 COMSOL 建模入口；
- 曲壳统一输出点与网格收敛；
- 近期文献对创新性的反向检索；
- 失败/负结果的结构化清单。

### Stress Test Results

| Test | Result |
|---|---|
| Remove strongest source — does argument hold? | 部分。机械链仍有独立 COMSOL；电/磁文献对标会明显减弱。 |
| Flip the research question — is opposing view credible? | 是。均匀材料或平板可能在部分指标上优于梯度曲壳。 |
| Apply to different context — does finding generalize? | 否。当前仅对指定几何、材料混合律与线性静力成立。 |
| “So what?” — is significance justified? | 有条件成立；必须形成可复用的曲率--梯度设计图，而非只列算例。 |

