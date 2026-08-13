# 位移反推与曲壳计算结果分析

本目录采用“正文、数据、来源说明、运行说明分开”的结构。老师阅读时只需打开 PDF；复核数值时查看 `data/` 和 `SOURCE_NOTES.md`。

## 文件

- `fgmee_data_analysis_report_20260721.pdf`：3--5 页的精简数据分析报告。
- `fgmee_data_analysis_report_20260721.tex`：LaTeX 源文件。
- `data/`：正文使用的数据快照。
- `figures/`：正文使用的四半径几何图。
- `SOURCE_NOTES.md`：数据来源、比较口径和未完成范围。
- `STYLE_CHECK.txt`：文字和版式自动检查结果。

## 编译

在 PowerShell 中运行：

```powershell
Set-Location 'G:\fg-meet-workbench\outputs\fgmee_data_analysis_report_20260721'
.\BUILD_REPORT.ps1
```

编译顺序是：文字检查、两次 XeLaTeX 编译、复制最终 PDF。中间文件保存在 `build/`，不会混入正文目录。

## 更新报告时的顺序

1. 先更新 `data/` 中的数据快照和 `SOURCE_NOTES.md`。
2. 修改 LaTeX 正文中的表格和解释。
3. 运行 `BUILD_REPORT.ps1`。
4. 将 PDF 渲染成图片，逐页检查分页、表格和中文字体。

写作规范和 GPT 提示词分别位于：

- `docs/reporting/DATA_ANALYSIS_REPORT_WORKFLOW_ZH.md`
- `docs/reporting/DATA_ANALYSIS_REPORT_PROMPT_ZH.md`

