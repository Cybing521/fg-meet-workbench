# 热释耦合重复装配代码审计报告计划

## 目标

生成一份可用 XeLaTeX 编译的中文分析报告，回答以下问题：

1. 实际修改的是当前 FG-MEE 工作台代码，还是钱沈云相关旧代码；
2. 旧代码缺陷位于哪些文件和代码行；
3. 为什么十层模型会产生热释电、热释磁耦合的十倍重复装配；
4. 当前采用了什么修正，为什么该修正对本次十层均匀材料算例成立；
5. 调整前后的 0.5、1.0、2.0 mm 感生电势与磁标势结果；
6. 当前 MATLAB 和 COMSOL 证据分别能证明到什么程度；
7. 对 X 型或其他逐层材料参数不同的功能梯度模型，还需要什么结构性修正。

## 数据与代码证据

- `matlab/meet-fem-core/SF_ElemComptLIN851T5MEEP_V4.m`
- `matlab/meet-fem-core/Main_FOSDLIN851T5MEEP_V4.m`
- `matlab/meet-fem-core/SF_Assembling.m`
- `matlab/run_meet_static.m`
- `run_matlab_inverse_pyro_fix_verification.m`
- `tools/analyze_inverse_pyro_overcount.py`
- `tools/comsol/RunInverseSensorCfffValidation.java`
- `outputs/paper-20260715-fgmee/experiments/inverse_sensing/*.csv`

## 报告结构

1. 执行摘要与直接结论；
2. 代码归属与 Git 追溯；
3. 原始装配缺陷的代码链；
4. 十倍重复装配的矩阵推导；
5. 当前修正的位置、机制与原因；
6. 调整前后数值结果；
7. MATLAB 直接回归与 COMSOL 后处理证据；
8. 已修复、未修复与适用边界；
9. 原始代码位置及复现命令附录。

## 验收标准

- `.tex` 使用 UTF-8 和 XeLaTeX；
- 成功编译 PDF，两次编译后无未解析交叉引用；
- 表中数值与 CSV 逐项一致；
- 明确“修正当前工作台入口，不是改写旧单元源码”；
- 不把 COMSOL 三维力学加本构后处理写成独立全耦合场验证；
- 不把钱沈云相关旧代码缺陷扩大为对其已发表论文整体正确性的否定。
