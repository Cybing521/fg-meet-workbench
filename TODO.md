# TODO

## 阶段 1 — MATLAB 冒烟（仓库已自带求解器）

- [x] MATLAB 求解器并入 `matlab/`
- [x] 统一入口 `matlab/run_meet_static.m`
- [x] COMSOL 文档与选点表 `comsol/`
- [ ] 新电脑：`setup_paths` → `run_phase1_static_elastic.m`
- [ ] 记录 `output/phase1_*.mat` 中 `w_center_mm`、`theta_layers`

## 阶段 2 — 参数化主算例（MATLAB）

- [ ] 扩展 `generate_cases.py`：5 种 FG × 9 个 Vf0
- [ ] `run_batch_static.m`：读 `cases/manifest_full.csv` 循环 Case A/B/C
- [ ] 汇总 `output/results_static.csv`（挠度、温差、磁电效率）

## 阶段 3 — COMSOL 验证

- [ ] 读 `comsol/README.md` 建基准模型
- [ ] `export_comsol_layers.py` 导入 10 层材料
- [ ] 按 `comsol/data/validation_points.csv` 对比 ≥15 组
- [ ] 填写 `comsol/results/validation_log.csv`，偏差 &lt; 5%

## 阶段 4 — 论文

- [ ] 动力代表算例（Newmark）
- [ ] 更新 `paper/main.tex` 图表
