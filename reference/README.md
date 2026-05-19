# 参考输入样例

`fg-meep-sample-inputs/` 保存历史 **FG-MEEP 板壳频率/位移** 算例的部分输入文件（U/V/X/O 分布、不同体积分数与孔隙指数），用于：

- 核对本仓库 `materials/` 中 FG 混合律与分层格式；
- 对照 `tools/generate_cases.py` 生成的新输入是否合理。

本目录**不参与**热-弹全耦合主求解；主求解使用仓库根目录 `cases/` 下由工作流生成的 `Thermal_CFFF_*.txt`。
