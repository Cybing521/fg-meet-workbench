# COMSOL 载荷等效（Case A / B / C）

与 `matlab/run_meet_static.m` 中三种 loadCase 对应。

## Case A — 弹性-热（elastic）

- **MATLAB**：`LoadScale = -15000`，经表面载荷向量 `FusT` 施加均布压力。
- **COMSOL**：顶面均布压力 15000 Pa（方向与板法向一致）。

## Case B — 电-热（electro）

- **MATLAB**：上下表面电势 ±300 V（`PhiaMT` 分层自由度）。
- **COMSOL**：在压电/等效模型中施加边界电势；或按课题组既有流程转换为等效面力（仅上下表面层）。

注意：电载荷在板面内可产生 Θ1、Θ2 方向等效应力，中心线位移形态与纯弯曲不同。

## Case C — 磁-热（magneto）

- **MATLAB**：上下表面磁势 ±200 A（`MgaT`）。
- **COMSOL**：对应磁边界或等效载荷，符号与幅值与 MATLAB 保持一致。

## 0.6 均匀材料核对

均匀体积分数 Vf0=0.6 时，COMSOL 各层材料应与  
`cases/Thermal_CFFF_U_Vf0.6-30x30-10layer.txt`  
的 MATERIAL 段逐列一致（已由生成脚本与历史参考输入校准）。
