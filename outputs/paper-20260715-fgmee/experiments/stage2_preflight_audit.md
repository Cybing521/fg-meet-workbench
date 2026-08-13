# Stage 2 数值闭环执行预检

> **后续修正（2026-07-15）：** 本文件按执行时间保留预检、失败尝试和当时的修正前数值。后续矩阵审计发现反传感热释电/热释磁项被按 10 个物理层重复装配；论文最终结果应使用 0.5 mm 对应 78.4803 V、0.0309000 A，而不是本文件中的 164.6464 V、0.170393 A。直接电/磁模型后来均已成功运行，20×20 偏差进一步冻结为非同构模型形式差。当前总状态以 `stage2_experiment_result.md` 和新版 v2 报告为准。

## 结论

本机具备 MATLAB R2026a 和 COMSOL 6.0.0.318，可继续执行计算；但仓库现有的 CFFF 电/磁 `.mph` 文件不能直接充当独立 ±300 V/±200 A 验证。两个模型均是“固体力学 + 静电 + 压电效应”，没有直接磁场物理接口；电模型以两组相反的 4.934 MPa 跟随压力等效，磁模型以两组相反的 16.49 MPa 跟随压力等效。磁模型虽然位于“磁热耦合”目录，内部仍没有 Magnetic Fields 或磁标势物理场。

## 已核事实

| 项目 | 结果 |
|---|---|
| MATLAB | `D:\MATLAB\R2026a\bin\matlab.exe` |
| COMSOL batch | `D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe` |
| COMSOL installed | 6.0.0.318 |
| 旧模型最后计算版本 | 6.2.0.290 |
| 电模型 physics | SolidMechanics + Electrostatics + PiezoelectricEffect |
| 电模型实际载荷 | `+4.934e6/-4.934e6 Pa` paired follower pressure |
| 磁模型 physics | SolidMechanics + Electrostatics + PiezoelectricEffect |
| 磁模型实际载荷 | `-1.649e7/+1.649e7 Pa` paired follower pressure |
| 旧模型直接电势边界 | 只有 Ground；未发现非零 ElectricPotential feature |
| 旧模型直接磁势边界 | 不存在磁场/磁标势 physics |

核查方法为只读解析 `.mph` ZIP 容器内的 `modelinfo.xml` 与 `smodel.json`，没有重新求解或改写模型。

## 证据等级调整

1. 旧电模型：可作为“等效压力产生目标位移形态”的辅助复核；不能称为直接 ±300 V 独立验证。
2. 旧磁模型：可作为“等效压力复核”；不能称为 ±200 A 磁势直接验证。
3. 因为等效压力数值可能来自前人/MATLAB 换算，它不能排除共享转换错误。
4. 两个文件最后计算版本为 COMSOL 6.2，而本机为 6.0；必须先运行只读兼容性/许可证检查，不能直接覆盖原文件。

## 已执行命令组

### A. COMSOL 旧模型只读兼容性检查（已完成）

```powershell
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' -checklicense 'G:\fg-meet-workbench\COMSOL仿真\电热耦合\plate-CFFF-10layer.mph'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' -checklicense 'G:\fg-meet-workbench\COMSOL仿真\磁热耦合\plate-CFFF-10layer.mph'
```

该步骤不求解、不改写原模型，只确定 COMSOL 6.0 是否能识别 6.2 保存的文件及所需许可证。

两条命令均以退出码 0 完成，均返回 `CADIMPORT / COMSOL / MEMS`。这只证明许可证可识别，不证明 6.0 能完整加载并重算 6.2 保存模型。

### B. MATLAB 0.5/1.0/2.0 mm 确定性复算（已完成）

使用既有 `run_coupling_validation_2mm.m`，每次运行前设置 `FG_VALIDATE_TARGET_MM`，完成后立即把固定文件名复制到 Stage 2 独立目录。执行顺序为 0.5 → 1.0 → 2.0 mm；任一运行崩溃即停止，不自动重试。

初始化结果目录并备份当前固定名称结果：

```powershell
$ErrorActionPreference = 'Stop'
$root = 'G:\fg-meet-workbench'
$resultDir = Join-Path $root 'outputs\paper-20260715-fgmee\experiments\results'
New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($ext in @('csv', 'mat')) {
  $source = Join-Path $root "output\coupling_validation_2mm.$ext"
  if (Test-Path -LiteralPath $source) {
    Copy-Item -LiteralPath $source -Destination (Join-Path $resultDir "pre_run_${stamp}_coupling_validation_2mm.$ext")
  }
}
```

0.5 mm 工况：

```powershell
$ErrorActionPreference = 'Stop'
$root = 'G:\fg-meet-workbench'
$matlab = 'D:\MATLAB\R2026a\bin\matlab.exe'
$resultDir = Join-Path $root 'outputs\paper-20260715-fgmee\experiments\results'
$env:FG_VALIDATE_TARGET_MM = '0.5'
$log = Join-Path $resultDir 'coupling_validation_0p5mm.log'
& $matlab -batch "cd('G:/fg-meet-workbench'); run('run_coupling_validation_2mm.m')" 2>&1 | Tee-Object -FilePath $log
$exitCode = $LASTEXITCODE
Remove-Item Env:FG_VALIDATE_TARGET_MM -ErrorAction SilentlyContinue
if ($exitCode -ne 0) { throw "MATLAB 0.5 mm experiment failed with exit code $exitCode; see $log" }
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.csv') -Destination (Join-Path $resultDir 'coupling_validation_0p5mm.csv')
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.mat') -Destination (Join-Path $resultDir 'coupling_validation_0p5mm.mat')
```

1.0 mm 工况：

```powershell
$ErrorActionPreference = 'Stop'
$root = 'G:\fg-meet-workbench'
$matlab = 'D:\MATLAB\R2026a\bin\matlab.exe'
$resultDir = Join-Path $root 'outputs\paper-20260715-fgmee\experiments\results'
$env:FG_VALIDATE_TARGET_MM = '1.0'
$log = Join-Path $resultDir 'coupling_validation_1p0mm.log'
& $matlab -batch "cd('G:/fg-meet-workbench'); run('run_coupling_validation_2mm.m')" 2>&1 | Tee-Object -FilePath $log
$exitCode = $LASTEXITCODE
Remove-Item Env:FG_VALIDATE_TARGET_MM -ErrorAction SilentlyContinue
if ($exitCode -ne 0) { throw "MATLAB 1.0 mm experiment failed with exit code $exitCode; see $log" }
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.csv') -Destination (Join-Path $resultDir 'coupling_validation_1p0mm.csv')
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.mat') -Destination (Join-Path $resultDir 'coupling_validation_1p0mm.mat')
```

2.0 mm 工况：

```powershell
$ErrorActionPreference = 'Stop'
$root = 'G:\fg-meet-workbench'
$matlab = 'D:\MATLAB\R2026a\bin\matlab.exe'
$resultDir = Join-Path $root 'outputs\paper-20260715-fgmee\experiments\results'
$env:FG_VALIDATE_TARGET_MM = '2.0'
$log = Join-Path $resultDir 'coupling_validation_2p0mm.log'
& $matlab -batch "cd('G:/fg-meet-workbench'); run('run_coupling_validation_2mm.m')" 2>&1 | Tee-Object -FilePath $log
$exitCode = $LASTEXITCODE
Remove-Item Env:FG_VALIDATE_TARGET_MM -ErrorAction SilentlyContinue
if ($exitCode -ne 0) { throw "MATLAB 2.0 mm experiment failed with exit code $exitCode; see $log" }
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.csv') -Destination (Join-Path $resultDir 'coupling_validation_2p0mm.csv')
Copy-Item -LiteralPath (Join-Path $root 'output\coupling_validation_2mm.mat') -Destination (Join-Path $resultDir 'coupling_validation_2p0mm.mat')
```

拟保存结果：

- `experiments/results/coupling_validation_0p5mm.csv/.mat/.log`
- `experiments/results/coupling_validation_1p0mm.csv/.mat/.log`
- `experiments/results/coupling_validation_2p0mm.csv/.mat/.log`

三次运行均以退出码 0 完成，结果文件已按上述名称冻结。三个位移工况的反向感知结果严格线性：电势分别为 164.646372、329.292745、658.585490；磁势分别为 0.170392625、0.340785250、0.681570500。

### C. 新建直接 COMSOL 模型（代码与编译已完成）

旧模型审计已经证明不能满足独立性。下一实现应新建：

- 直接电势边界的压电模型（300 V 工况，先澄清论文“±300 V”是总差 300 V 还是两面各 ±300 V）；
- 磁标势或数学同构 PDE 的磁致伸缩模型（200 A 工况）；
- 反向感知模型，位移边界为 0.5/1.0 mm，输出电势、磁势及参考势定义。

在载荷语义没有从前人公式/原始模型冻结之前，不把等效压力改名为直接电/磁验证。

已新增且编译通过：

- `tools/comsol/RunDirectElectroCfffValidation.java/.class`
- `tools/comsol/RunDirectMagneticCfffValidation.java/.class`

电模型在上下外层直接设置 300 V 层间电势，调用 Solid Mechanics + Electrostatics + Piezoelectric Effect；磁模型在上下外层直接解归一化磁标势拉普拉斯方程，并由 `H_z=-dV_m/dz` 和 `q31/q32` 形成外加本构应力。两者均不读取旧 `.mph`，也不施加预先计算的等效面压力。

### D. 新模型固定求解命令

电势正向工况（300 V，15×15×10）：

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_electro_300V_15x15x10'
$env:FG_DIRECT_VOLTAGE='300'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectElectroCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10.log'
```

磁势正向工况（200 A，15×15×10）：

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_magnetic_200A_15x15x10'
$env:FG_DIRECT_MAGNETIC_POTENTIAL_A='200'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectMagneticCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_magnetic_200A_15x15x10.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_magnetic_200A_15x15x10.log'
```

执行约束：每条命令硬超时 30 分钟，约每 30 秒检查日志；任何失败均停止，不自动更改模型或重试。

## 首次直接求解尝试记录

2026-07-15 12:36，按上述电势命令启动首轮直接求解。操作系统进程返回 0，但 COMSOL 日志明确报告：

```text
错误几何实体层上的选择。
 - 选择: sel_bottom_outer
```

没有生成 summary CSV，故该次尝试判定为失败，不能计入完成率。错误发生在映射网格读取命名边界选择时，尚未进入求解器。磁模型未继续运行。

只读诊断显示 `sel_bottom_outer` 本身确实解析为一个边界实体；问题位于 Mesh API 对命名选择的实体层绑定。修正版将映射面、边和 Sweep source face 冻结为几何构建后取得的显式实体编号；电/磁两份驱动同步修改并重新编译，但不会在本次失败后自动重跑。第二次电求解和第一次磁求解须作为新的实验尝试另行确认。

## 修正版待确认命令

电模型第二次尝试将保留首轮失败文件，使用新的 tag 和日志：

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_electro_300V_15x15x10_attempt2'
$env:FG_DIRECT_VOLTAGE='300'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectElectroCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt2.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt2.log'
```

若该次正常求解并生成 summary CSV，再执行本文件 D 节已经冻结的 200 A 磁模型命令；任一失败仍停止，不自动重试。两条求解的硬超时均为 30 分钟。

## 第二次尝试结果与根因定位

2026-07-15 12:43，修正版电模型第二次启动。进程仍返回 0，但日志再次报告同一错误且没有 summary CSV，因此仍判定失败，磁模型未启动。

第二次失败模型的 `dmodel.xml` 给出了决定性证据：

- `sel_bottom_outer` 本身是合法的二维边界选择，包含一个面；
- `sel_outer_electrodes` 的 `Union` 因创建时未设置 `entitydim`，被 COMSOL 默认建成三维域选择；
- 该三维 Union 接收 `sel_bottom_outer/sel_top_outer` 两个二维边界输入，触发“错误几何实体层上的选择”；
- 因异常发生在求取 Union 计数时，代码尚未进入材料、物理场和网格构建，故第一次修改网格引用不会改变结果。

根因修正为：所有 Union 创建均显式传入实体维度。电模型的内/外电极 Union 固定为 2D；磁模型的外层域 Union 固定为 3D，内/外磁势面 Union 固定为 2D。两份驱动均已重新编译。

## 第三次尝试待确认命令

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_electro_300V_15x15x10_attempt3'
$env:FG_DIRECT_VOLTAGE='300'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectElectroCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt3.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt3.log'
```

第三次仍使用 30 分钟硬超时并保留前两次失败产物；只有日志无错误且生成 summary CSV 才启动 D 节的 200 A 磁模型。

## 第三次尝试结果与下一处 API 兼容问题

2026-07-15 12:50，第三次电模型启动后已成功输出：

```text
DIRECT_ELECTRO_SELECTIONS,fixed,10,bottom_domain,1,top_domain,1,outer_electrodes,2,inner_electrodes,2
```

这证明 Union 实体维度修正生效。随后 COMSOL 报告“不可编辑选择”，仍没有生成 summary CSV，故第三次失败，磁模型未启动。

第三次失败模型的最后历史操作为创建 Solid Mechanics 并设置位移阶次；下一条源代码操作是尝试修改默认 `lemm1` 的选择。COMSOL 6.0 的默认 Linear Elastic Material 节点继承物理场选择，其选择不可编辑。该行已删除：默认 `lemm1` 保持覆盖全部域，两个外层的 `PiezoelectricMaterialModel` 通过材料模型覆盖机制接管对应域，内八层继续使用默认线弹性模型。修正版已重新编译。

## 第四次尝试待确认命令

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_electro_300V_15x15x10_attempt4'
$env:FG_DIRECT_VOLTAGE='300'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectElectroCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt4.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt4.log'
```

第四次继续使用 30 分钟硬超时并保留前三次失败产物；成功判据不变。

## 第四次尝试结果与静电域范围修正

2026-07-15 14:07，第四次电模型已完成：

- 全部选择计数；
- 22,500 个扫掠六面体单元；
- 492,969 个自由度的方程编译；
- 稳态矩阵组装启动。

随后求解器报告：

```text
未定义“电荷守恒 1”所需的材料属性“epsilonr”
```

没有 summary CSV，故第四次仍失败，磁模型未启动。原因是 Electrostatics 接口默认覆盖全部十层；两个 `ChargeConservationPiezo` 只覆盖上下外层，内八层仍落入默认 `Charge Conservation 1`，而内层只提供结构材料参数，没有 `epsilonr`。

修正方案不是给内层随意补一个介电常数，而是将 Electrostatics 接口的物理场域严格限制到上下两个独立外压电层。为此新增 3D `sel_outer_dom` Union，并把 `es` 的选择绑定到该 Union。修正版已重新编译。

## 第五次尝试待确认命令

```powershell
$env:FG_DIRECT_OUTPUT_DIR='G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol'
$env:FG_DIRECT_RUN_TAG='direct_electro_300V_15x15x10_attempt5'
$env:FG_DIRECT_VOLTAGE='300'
$env:FG_DIRECT_INPLANE_DIVISIONS='15'
$env:FG_DIRECT_THICKNESS_DIVISIONS='10'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'G:\fg-meet-workbench\tools\comsol\RunDirectElectroCfffValidation.class' `
  -outputfile 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt5.mph' `
  -batchlog 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\comsol\comsol_direct_electro_300V_15x15x10_attempt5.log'
```

第五次继续使用 30 分钟硬超时并保留前四次失败产物；成功判据不变。

## 第五次求解、后处理恢复与端到端复核

第五次电模型完成 340,170 个自由度的线性求解，求解器正常收敛，用时 25 s，峰值物理内存约 6.56 GB。随后原驱动在正好位于外压电层/内结构层界面的电势插值点失败；该点被 COMSOL 归入没有电势变量的内层域。求解结果本身已保存。

使用独立恢复程序从已收敛解中把界面查询点向外压电层偏移 `1e-9 m`，成功得到：

- 中心位移：`-0.0580492827 mm`；
- 下/上外层电势：约 `300/0 V`；
- 下/上外层电场：约 `+5.0e5/-5.0e5 V/m`；
- 相对 MATLAB `-0.0522570949 mm` 的偏差：`11.0840%`。

正式电驱动同步修正后，以 `direct_electro_300V_15x15x10_attempt6_final` 从头运行，日志无错误并自动生成 summary CSV，中心位移为 `-0.0580492820 mm`，与恢复值一致到 `1e-9 mm` 量级。

## 200 A 磁模型与三档网格结果

磁模型在 15×15×10 首次正式运行即正常结束，自动生成 summary CSV：

- 中心位移：`0.1904350676 mm`；
- 下/上外层磁场：`+3.333333e5/-3.333333e5 A/m`；
- 下/上外层本构应力：`-16.49/+16.49 MPa`；
- 相对 MATLAB `0.1745857472 mm` 的偏差：`9.0782%`。

随后完成电、磁各三档面内网格：

| 链路 | 10×10 / mm | 15×15 / mm | 20×20 / mm | 15→20 变化 | 20×20 对 MATLAB 偏差 |
|---|---:|---:|---:|---:|---:|
| 300 V 电致位移 | -0.0584219031 | -0.0580492820 | -0.0578865885 | 0.2811% | 10.7727% |
| 200 A 磁致位移 | 0.1900171605 | 0.1904350676 | 0.1907662164 | 0.1736% | 9.2679% |

六个正式网格日志均无错误且 status 为 completed。两条链路均通过 0.5% 网格变化门槛，但均未通过 1% MATLAB--COMSOL 一致性门槛。故最终判断是：运行链路与网格收敛已经闭合，剩余 9%--11% 为系统性模型口径差异，不能通过继续细化网格消除。
