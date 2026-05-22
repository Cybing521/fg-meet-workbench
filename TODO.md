# TODO

## 阶段 1 — MATLAB 冒烟（仓库已自带求解器）

- [x] MATLAB 求解器并入 `matlab/`
- [x] 统一入口 `matlab/run_meet_static.m`
- [x] COMSOL 文档与选点表 `comsol/`
- [x] 新电脑：`setup_paths` → `run_phase1_static_elastic.m`
- [x] 记录 `output/static_elastic_phase1_U_Vf06.mat` 中 `w_center_mm`、`theta_layers`（见 `output/phase1_static_elastic_summary.csv`）

## 阶段 2 — 参数化主算例（MATLAB）

- [x] 扩展 `generate_cases.py`：5 种 FG × 9 个 Vf0
- [x] `run_batch_static.m`：读 `cases/manifest_full.csv` 循环 Case A/B/C
- [x] 在 MATLAB 环境运行 `run_batch_static.m`，汇总 `output/results_static.csv`（挠度、温差、磁电效率）
- [x] 修正 `run_meet_static.m` 的约束后 `Qd` 位移提取：先还原完整 5-DOF 节点向量 `TQd`，再按坐标取中心挠度
- [x] 用修正后的中心挠度提取方式刷新 `output/results_static.csv`（备份和报告见 `output/results_static.pre-wcenter-refresh-*.csv`、`output/results_static_w_center_refresh_report.csv`）

## 阶段 2.5 — 2 mm 转化验证（MATLAB）

- [x] `run_coupling_validation_2mm.m`：电势/磁势 → 2 mm 挠度正向标定
- [x] 2 mm 机械挠度 → 电势/磁势反向传感验证
- [x] 按沈的回代方式计算磁势→位移→感生电势、电势→位移→感生磁势，结果见 `output/coupling_validation_2mm.csv`

## 阶段 3 — COMSOL 验证

- [x] 读 `comsol/README.md`，建立 COMSOL CLI 基准模型（`tools/comsol/RunElasticCfffValidation.java`）
- [x] `export_comsol_layers.py` 导出 45 个主算例的 10 层材料 CSV（见 `comsol/export/`）
- [x] 在 COMSOL 模型中导入 10 层材料 CSV（`FG_COMSOL_LAYERED=true`，每层单独域和材料选择）
- [x] 完成 U / Vf0.6 / CFFF / Case A 的 15 点 COMSOL 对比（见 `comsol/results/validation_points_U_Vf06_elastic.csv`）
- [x] 填写 `comsol/results/validation_log.csv`
- [x] COMSOL 偏差收敛到 &lt; 5%：10 层 CSV 分域材料 + swept quad/hex 网格、mesh size 4、每层 7 个扫掠单元时中心点 3.77%，15 点最大 4.927%

## 阶段 4 — 动力代表算例

- [x] 新增 `run_dynamic_representative.m`，统一 Newmark 动力代表算例入口
- [x] 完成 U / Vf0.6 / CFFF / Case A 的 10x10 pilot 动力结果：401 步、40 ms、峰值 -4.4995 mm、第一阶频率 52.20 Hz
- [x] 输出动态补充汇报材料 `reports/2026-05-22-dynamic/README.md` 与 5 张可截取图片
- [x] 30x30 全量 Newmark 暂不适合作为交互式计算入口：1 ms 冒烟测试超过 5 min，已改做 30x30 模态降阶
- [x] 完成 U / Vf0.6 / CFFF / Case A 的 30x30 8 阶模态动力结果：模态静态捕获比例 1.00037，峰值 -4.4279 mm，第一阶频率 52.20 Hz
- [x] 输出 30x30 模态汇报材料 `reports/2026-05-22-modal30x30/README.md` 与 6 张可截取图片
- [x] 完成 30x30 模态阶数敏感性（4/6/8/12/16 阶）：16 阶峰值 -4.4270 mm，峰值时间 9.60 ms；与 8 阶峰值差约 0.0009 mm
- [x] 输出阶数敏感性汇报材料 `reports/2026-05-22-modal-sensitivity/README.md` 与 8 张可截取图片
- [x] 完成 30x30 16 阶模态阻尼敏感性（0/0.5/0.8/1.5%）：峰值从 -4.5039 mm 降到 -4.3858 mm
- [x] 输出阻尼敏感性汇报材料 `reports/2026-05-23-modal-damping/README.md` 与 6 张可截取图片
- [ ] 如需论文最终动态图，可继续补完整 Newmark 夜间长任务对照

## 阶段 5 — 论文

- [ ] 更新 `paper/main.tex` 图表
