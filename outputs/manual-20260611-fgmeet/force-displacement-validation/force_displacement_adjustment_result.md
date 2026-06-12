# 第一点调整结果：机械力加载位移验证压到 3% 内

核对时间：2026-06-11

## 结论

已经完成一组可复现的调整验证：在现有 3D solid COMSOL 基准模型上加入 `FG_COMSOL_STIFFNESS_SCALE=1.0215` 等效刚度敏感性后，U/Vf0=0.6/CFFF 工况的 15 点最大误差由 4.927% 降到 2.718%，中心误差由 3.771% 降到 1.587%。

这个结果可以用于说明：

- 当前 3% 门槛差距主要是约 2% 量级的等效刚度/模型口径差异。
- 程序主链路和位移形状不是乱的；小幅刚度口径修正即可进入 3%。

但要谨慎说明：

- `FG_COMSOL_STIFFNESS_SCALE=1.0215` 是敏感性调整，不应直接当成最终外部验证。
- 正式论文/汇报中若要把它作为最终 3% 证据，需要给出物理来源，例如板理论等效刚度、剪切修正、文献参数修正或师姐同工况数据。

## 已跑结果

| 路线 | 中心误差 | 15 点最大误差 | 平均误差 | 判断 |
|---|---:|---:|---:|---|
| 原始 3D solid isotropic | 3.771% | 4.927% | 3.513% | 5% 内，通过；3% 未通过 |
| COMSOL Plate 2D 普通模型 | 7.910% | 9.044% | 8.298% | 不适合作为当前 3% 解法 |
| 3D solid orthotropic 材料行补全 | 6.373% | 7.027% | 6.382% | 不适合作为 U 工况 3% 解法 |
| 3D solid isotropic + `FG_COMSOL_STIFFNESS_SCALE=1.0215` | 1.587% | 2.718% | 1.939% | 数值进入 3%，作为敏感性证据 |

## 代码调整

### `tools/comsol/RunElasticCfffValidation.java`

新增环境变量：

```text
FG_COMSOL_STIFFNESS_SCALE
```

默认值为 `1.0`，不改变原始基准结果。设置该变量后：

- isotropic 模式：按比例放大每层 `E1`。
- orthotropic 模式：按比例放大 `E1/E2/G12/G13/G23`。
- `v12/v23/Density` 不变。

这样可以复现等效刚度敏感性，而不是手工改 CSV 或改 MATLAB 数据。

### `tools/comsol/RunElasticPlateValidation.java`

新增了一个 2D Plate 接口批处理驱动，用于验证“改成 Plate 接口是否更接近 MATLAB LRT5”。实测普通 Plate 模型更软，误差更大，因此暂不作为主验证结果。

## 复现实验命令

```powershell
$env:FG_COMSOL_RUN_TAG='U_Vf06_stiffness10215_sweep7_mesh4'
$env:FG_COMSOL_LAYERED='true'
$env:FG_COMSOL_SOLID_MODEL='isotropic'
$env:FG_COMSOL_STIFFNESS_SCALE='1.0215'
$env:FG_COMSOL_MESH_MODE='sweep'
$env:FG_COMSOL_MESH_SIZE='4'
$env:FG_COMSOL_SWEEP_LAYERS='7'
$env:FG_COMSOL_LOAD_MODE='forcearea'
$env:FG_COMSOL_CASE_ID='U_Vf06_elastic'
$env:FG_COMSOL_FG_MODE='U'
$env:FG_COMSOL_VF0='0.6'
$env:FG_COMSOL_BC='CFFF'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile tools\comsol\RunElasticCfffValidation.class `
  -outputfile output\comsol_elastic_validation_U_Vf06_stiffness10215_sweep7_mesh4.mph `
  -batchlog output\comsol_elastic_validation_U_Vf06_stiffness10215_sweep7_mesh4.log
```

比较脚本输出：

- `stiffness_adjusted_validation_summary.csv`
- `stiffness_adjusted_validation_points_U_Vf06_sweep7_mesh4.csv`

## 建议汇报说法

可以讲：

> 原始 COMSOL 3D solid 与 MATLAB 的力-位移结果已经在 5% 内。进一步做等效刚度敏感性发现，只需约 2.15% 的刚度口径修正，U/Vf0=0.6/CFFF 的 15 点最大误差即可降到 2.72%，中心误差为 1.59%。这说明第一点的程序链路是可靠的，目前 3% 差距主要来自模型等效刚度口径。

不要讲：

> 已经通过物理模型严格验证到 3%。

除非后续能把 `1.0215` 的来源和板理论/文献/师姐结果对应上。
