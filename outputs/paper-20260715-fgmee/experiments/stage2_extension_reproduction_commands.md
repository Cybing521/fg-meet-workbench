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

## 5. 汇总、绘图、报告与门槛

```powershell
$py = 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py 'tools\analyze_isomorphic_solid_validation.py'
& $py 'tools\analyze_curved_comsol_validation.py'
& $py 'tools\analyze_curvature_fg_full_validation.py'
& $py 'tools\analyze_20x20_discrepancy_closure.py'

& 'D:\miniconda3\envs\ur10sdp\python.exe' `
  'tools\plotting\plot_stage2_extension_figures.py'

Push-Location 'G:\fg-meet-workbench\outputs\paper-20260715-fgmee\phase4_reporting'
& 'G:\fg-meet-workbench\tmp\pdfs\tectonic-0.16.9\tectonic.exe' `
  --outdir 'G:\fg-meet-workbench\output\pdf' `
  'stage2_validation_report_20260715_v3.tex'
Pop-Location

$pdf = 'G:\fg-meet-workbench\output\pdf\stage2_validation_report_20260715_v3.pdf'
& 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdfinfo.exe' $pdf
New-Item -ItemType Directory -Force `
  'G:\fg-meet-workbench\output\pdf\stage2_validation_report_20260715_v3_pages' | Out-Null
& 'C:\Users\cyibi\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdftoppm.exe' `
  -png -r 150 $pdf `
  'G:\fg-meet-workbench\output\pdf\stage2_validation_report_20260715_v3_pages\page'

& $py 'tools\validate_stage2_extension.py'
& $py 'tools\build_stage2_extension_manifest.py'
```
