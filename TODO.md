# TODO — FG-MEET 参数化仿真

> 换机后先看 [README.md](README.md) 的「新电脑配置」一节。

## 阶段 1：环境与单工况验证

- [ ] 新电脑安装 MATLAB（建议 R2020b+）
- [ ] 复制 `config_paths_local.example.m` → `config_paths_local.m` 并填写 MEET 程序路径
- [ ] 从 U 盘/网盘拷贝 **钱沈云** `MEET-elastic-thermal` + `SubFunMFC`（勿上传公开仓库）
- [ ] `setup_paths` 无报错
- [ ] 运行 `run_phase1_static_elastic.m`（U, Vf0=0.6, 力载荷 15000 Pa）
- [ ] 记录中心挠度 `w_center_mm` 与 10 层温差 `theta_layers`
- [ ] 与钱沈云原算例 `Thermal_CFFFplate_0.6Vf-30x30-10layer` 对比（材料段已校准为 maxRelDiff=0）

## 阶段 2：扩展输入文件（5×9 组合）

- [ ] 扩展 `tools/generate_cases.py`：FG 模式 U/V/X/O/P，Vf0 = 0.1:0.1:0.9
- [ ] 生成全部 `cases/Thermal_CFFF_{mode}_Vf{x}-30x30-10layer.txt`
- [ ] 更新 `cases/manifest_full.csv`
- [ ] 编写 `run_batch_static.m`：循环 Case A（力载荷）
- [ ] 编写 `run_batch_electro.m` / `run_batch_magneto.m`（Case B/C）
- [ ] 汇总 CSV：`output/results_static.csv`（挠度、温差 A–D、磁电效率）

## 阶段 3：COMSOL 对照

- [ ] 按 `汇报格式-MatlabComsol仿真记录.docx` 建立 COMSOL 分层模型
- [ ] 选 15–20 组代表工况比对 MATLAB
- [ ] 相对偏差 < 5% 写入论文

## 阶段 4：动力与论文

- [ ] 代表工况 Newmark 动力（CFFF / CFCF）
- [ ] 绘制：挠度–Vf、温差–FG 模式、磁电效率–Vf
- [ ] 填充 `paper/main.tex` 中 PLACEHOLDER 图表与表格

## 可选 / 后续

- [ ] 孔隙率 e0 参数（版本二思路）
- [ ] O 型、P 型（n=1,2,5）完整扫描
- [ ] 边界条件 CFCF / CFFC / CCFC 扩展
