# MATLAB--COMSOL 力致位移 LaTeX 报告

主文件：`force_displacement_validation_20260714.tex`

数据摘录：`report_data.csv`

已使用官方 Tectonic 0.16.9 成功编译，最终 PDF 位于：

`G:\fg-meet-workbench\output\pdf\force_displacement_validation_20260714.pdf`

也可以在安装了完整 TeX Live 或 MiKTeX 的 Windows 环境中重新编译：

```powershell
xelatex -interaction=nonstopmode -halt-on-error force_displacement_validation_20260714.tex
xelatex -interaction=nonstopmode -halt-on-error force_displacement_validation_20260714.tex
```

本文档使用 `ctexart` 与 `fontset=windows`。当前 PDF 由便携 Tectonic 编译，并使用 Poppler 逐页渲染检查。

报告明确区分：

- 45×45 完整耦合恒定面力成功结果；
- 5×5、10×10 随动压力严格复现结果；
- 45×45 随动压力的 COMSOL 6.0 内存失败边界。
