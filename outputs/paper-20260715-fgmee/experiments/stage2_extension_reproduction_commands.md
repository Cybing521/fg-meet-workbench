# Stage-2 扩展复现命令

以下命令均在 `G:\fg-meet-workbench` 的 PowerShell 中执行。

## 1. 曲率输入护照与 MATLAB 全半径复算

```powershell
& 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  'tools\generate_curvature_fg_cases.py'

& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch `
  "cd('G:/fg-meet-workbench'); run('run_matlab_curvature_fg_full_mesh_validation.m')"
```

复算脚本按 `mesh + mode + radius + load_case` 读取增量 CSV，已完成组合会跳过，因此中断后可直接执行同一命令续跑。

## 2. MATLAB H20 同构实体

```powershell
& 'D:\MATLAB\R2026a\bin\matlab.exe' -batch `
  "cd('G:/fg-meet-workbench'); run('run_matlab_isomorphic_solid_validation.m')"
```

## 3. COMSOL 同构实体

```powershell
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolcompile.exe' `
  'tools\comsol\RunIsomorphicSolidCfffValidation.java'

$env:FG_ISO_OUTPUT_DIR = 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\isomorphic_solid\comsol'
$env:FG_ISO_INPLANE_DIVISIONS = '20'
$env:FG_ISO_THICKNESS_PER_LAYER = '1'
$env:FG_ISO_LOAD_CASE = 'electric_equivalent_stress'
$env:FG_ISO_BOTTOM_STRESS_PA = '4934000'
$env:FG_ISO_TOP_STRESS_PA = '-4934000'
$env:FG_ISO_RUN_TAG = 'electric_equivalent_stress_20x'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'tools\comsol\RunIsomorphicSolidCfffValidation.class' `
  -outputfile "$env:FG_ISO_OUTPUT_DIR\comsol_isomorphic_electric_equivalent_stress_20x.mph" `
  -batchlog "$env:FG_ISO_OUTPUT_DIR\comsol_isomorphic_electric_equivalent_stress_20x.log"
```

磁载荷把上下层应力改为 `-16490000` 和 `16490000`，并把 load case/tag 改为 `magnetic_external_stress`；10/15 网格仅修改面内划分数。

## 4. 代表曲壳 COMSOL

```powershell
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolcompile.exe' `
  'tools\comsol\RunCurvedSolidCfffValidation.java'

$env:FG_CURVED_OUTPUT_DIR = 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\experiments\curvature_fg\comsol'
$env:FG_CURVED_RADIUS_M = '0.4'
$env:FG_CURVED_PRESSURE_PA = '15000'
$env:FG_CURVED_AXIAL_DIVISIONS = '20'
$env:FG_CURVED_CIRC_DIVISIONS = '20'
$env:FG_CURVED_THICKNESS_DIVISIONS = '10'
$env:FG_CURVED_RUN_TAG = 'U_R0p4_20x20x10_final'
& 'D:\comsol\COMSOL60\Multiphysics\bin\win64\comsolbatch.exe' `
  -inputfile 'tools\comsol\RunCurvedSolidCfffValidation.class' `
  -outputfile "$env:FG_CURVED_OUTPUT_DIR\comsol_curved_U_R0p4_20x20x10_final.mph" `
  -batchlog "$env:FG_CURVED_OUTPUT_DIR\comsol_curved_U_R0p4_20x20x10_final.log"
```

## 5. 位移目标的外加载势反算与 COMSOL 直接场回代

下列入口对 0.5、1.0、2.0 mm 三个目标分别运行电致和磁致 COMSOL 正向场模型。默认 `-LoadBasis comsol`，用于检验 COMSOL 链按自身灵敏度反算后能否自洽回代；每个目标都是独立求解，不使用感生势后处理模型。随后两条 `-LoadBasis matlab` 命令把 MATLAB 的 0.5 mm 反算载荷原样输入 COMSOL，形成真正的跨模型交叉施加。

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'tools\comsol\run_inverse_actuation_validation.ps1' -Mode all -TargetMm all -InplaneDivisions 20 -ThicknessDivisionsPerLayer 10
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'tools\comsol\run_inverse_actuation_validation.ps1' -Mode electric -TargetMm 0.5 -LoadBasis matlab -InplaneDivisions 20 -ThicknessDivisionsPerLayer 10
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'tools\comsol\run_inverse_actuation_validation.ps1' -Mode magnetic -TargetMm 0.5 -LoadBasis matlab -InplaneDivisions 20 -ThicknessDivisionsPerLayer 10
$py = 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py 'tools\audit_inverse_potential_validation.py'
~~~

若需中断后续跑单个目标，可把 `-Mode` 设为 `electric` 或 `magnetic`，并把 `-TargetMm` 设为 0.5、1.0 或 2.0。当前报告只把已经实际运行的 0.5 mm 两个 `-LoadBasis matlab` 交叉工况列入证据；其他目标即使按线性关系可预测，也必须真实运行并更新证据清单后才能写入结果。

## 6. 汇总、绘图、报告与门槛

```powershell
$py = 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py 'tools\analyze_isomorphic_solid_validation.py'
& $py 'tools\analyze_curved_comsol_validation.py'
& $py 'tools\analyze_curvature_fg_full_validation.py'
& $py 'tools\analyze_20x20_discrepancy_closure.py'
& $py 'tools\audit_inverse_potential_validation.py'

& 'D:\miniconda3\envs\ur10sdp\python.exe' `
  'tools\plotting\plot_stage2_extension_figures.py'

Push-Location 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting'
& 'G:\fg-meet-workbench\tmp\pdfs\tectonic-0.16.9\tectonic.exe' `
  --keep-logs --keep-intermediates `
  --outdir 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting' `
  'fgmee_latest_feasible_results_report_20260715.tex'
Pop-Location

$pdf = 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting\fgmee_latest_feasible_results_report_20260715.pdf'
& 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdfinfo.exe' $pdf
New-Item -ItemType Directory -Force `
  'G:\fg-meet-workbench\tmp\pdf_qa_20260719\pages_v3' | Out-Null
& 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdftoppm.exe' `
  -png -r 120 $pdf `
  'G:\fg-meet-workbench\tmp\pdf_qa_20260719\pages_v3\page'

& $py 'tools\validate_stage2_extension.py'
& $py 'tools\build_stage2_extension_manifest.py'
```
