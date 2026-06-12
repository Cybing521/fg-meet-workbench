# 第三点外部结果导出要求

更新时间：2026-06-12

## 目的

第三点要验证的是：

> 加力产生位移后，再由该位移场回代得到电势或磁势。

当前我们已经有内部新口径结果，并且已经用钱沈云代码同工况复跑对上：

| 项目 | 当前内部结果 |
|---|---:|
| 机械 2 mm 对应载荷缩放 | `load_scale=-14100.9259357` |
| 位移 -> 电势层平均 span | 我们 `658.585489735105`；钱沈云复跑 `658.585489735107` |
| 位移 -> 磁势层平均 span | 我们 `0.681570500460290`；钱沈云复跑 `0.681570500460291` |

所以第 3 点已经可以写成“钱沈云代码同工况验证已完成”。本文件现在只作为可选补强：如果导师要求论文表格、COMSOL 或师姐原始导出文件作为直接证据，再按下面格式导出。

## 可选补强时最小需要导出的外部变量

若要补论文/COMSOL之外的原始结果文件，优先从钱沈云 RWR 静力代码或师姐原始程序导出：

| 变量 | 必需性 | 说明 |
|---|---|---|
| `Y_Disp` | 必需 | 用来确认外部工况的位移量级和取点位置。 |
| `Y_SensM_E` | 必需其一 | 位移回代电势输出；如果只做磁势，可暂不导出。 |
| `Y_SensM_M` | 必需其一 | 位移回代磁势输出；如果只做电势，可暂不导出。 |
| `X_Lamda` | 建议 | 用来确认载荷步或缩放量。 |
| `PositionM` | 建议 | 机械位移取点编号。 |
| `PositionMEE` | 建议 | 电/磁势取点编号。 |
| `Qd1` | 建议 | 最终位移全场，可用于复查回代输入。 |

最理想文件名：

`qian_point3_CFFF_U_Vf06_force_to_em_YYYYMMDD.mat`

如果只能导出 CSV，建议至少包含：

```text
case_name,load_scale,disp_probe_mm,electric_min,electric_max,electric_span,magnetic_min,magnetic_max,magnetic_span
```

## 钱沈云代码中的对应位置

文件：

`reference/predecessor-code/qian-shenyun/双向耦合程序-new/双向耦合程序-new/SubFunMFC/Main_StaticNL851T5T56MEEP_RWR_V4.m`

已经确认的公式入口：

```matlab
AA=[KffMT1,KfzT1; KzfT1,KzzT1];
BB=[-KfuMT1*Qd1-KftT1*DeltaT-GfiMT1; -KzuT1*Qd1-KztT1*DeltaT-MziT1];
CC=AA\BB;
SensM_E = CC(1:Tot_DOF_MEE);
SensM_M = CC(Tot_DOF_MEE+1:end);
Y_SensM_E(:,LoadIndex+1) = SensM_E(PositionMEE);
Y_SensM_M(:,LoadIndex+1) = SensM_M(PositionMEE);
```

函数末尾已经返回：

```matlab
XY_Value = struct('Y_Disp',Y_Disp,'X_Lamda',X_Lamda, ...
                 'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M, ...
             'Y_ErrorRatio',Y_ErrorRatio,'Qd1',Qd1);
```

所以只要复跑同工况并保存 `XY_Value` 即可：

```matlab
save('qian_point3_CFFF_U_Vf06_force_to_em_YYYYMMDD.mat', ...
     'XY_Value', 'PositionM', 'PositionMEE', 'InputFile', 'FueT', 'DeltaT');
```

## 导入后的判定口径

导入外部结果后，先做两个检查：

1. 位移量级是否同工况：外部 `Y_Disp` 的中心位移或自由端位移要和当前力载荷结果在同一量级。
2. 电/磁势取法是否一致：比较同一组 `PositionMEE` 或相同层平均/跨度。

通过后再输出误差表：

| 项目 | 我们程序 | 外部结果 | 相对误差 | 判断 |
|---|---:|---:|---:|---|
| 位移 -> 电势 span | `658.5854897` | 待导入 | 待算 | 待定 |
| 位移 -> 磁势 span | `0.6815705005` | 待导入 | 待算 | 待定 |

## 当前不能替代外部验证的材料

- `CFFF_SensM_T.mat` 只有 `SensM_T sparse 9000x1`，是温度/热响应，不是电势/磁势。
- `CFFF位移to温差-位移图.fig` 是位移/温差相关曲线，不能当作 `Y_SensM_E/Y_SensM_M`。
- 赵亚飞 `FG_MEEP_Thermal_output_pointial.m` 是方法例子，但活动工况为 `SSSS-FG-MEEP-U.txt`，不是当前 CFFF 方板同工况。
