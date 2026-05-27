# TODO

## 阶段 1 — MATLAB 冒烟（仓库已自带求解器）✅

- [x] MATLAB 求解器并入 `matlab/`
- [x] 统一入口 `matlab/run_meet_static.m`
- [x] COMSOL 文档与选点表 `comsol/`
- [x] 新电脑：`setup_paths` → `run_phase1_static_elastic.m`
- [x] 记录 `output/static_elastic_phase1_U_Vf06.mat` 中 `w_center_mm`、`theta_layers`（见 `output/phase1_static_elastic_summary.csv`）

## 阶段 2 — 参数化主算例（MATLAB）✅

- [x] 扩展 `generate_cases.py`：5 种 FG × 9 个 Vf0
- [x] `run_batch_static.m`：读 `cases/manifest_full.csv` 循环 Case A/B/C
- [x] 在 MATLAB 环境运行 `run_batch_static.m`，汇总 `output/results_static.csv`（挠度、温差、磁电效率）
- [x] 修正 `run_meet_static.m` 的约束后 `Qd` 位移提取：先还原完整 5-DOF 节点向量 `TQd`，再按坐标取中心挠度
- [x] 用修正后的中心挠度提取方式刷新 `output/results_static.csv`

## 阶段 2.5 — 2 mm 转化验证（MATLAB）✅

- [x] `run_coupling_validation_2mm.m`：电势/磁势 → 2 mm 挠度正向标定
- [x] 2 mm 机械挠度 → 电势/磁势反向传感验证
- [x] 按沈的回代方式计算磁势→位移→感生电势、电势→位移→感生磁势，结果见 `output/coupling_validation_2mm.csv`

## 阶段 3 — COMSOL 验证 ✅

- [x] 建立 COMSOL CLI 基准模型（`tools/comsol/RunElasticCfffValidation.java`）
- [x] `export_comsol_layers.py` 导出 45 个主算例的 10 层材料 CSV
- [x] 在 COMSOL 模型中导入 10 层材料 CSV（每层单独域和材料选择）
- [x] 完成 U / Vf0.6 / CFFF / Case A 的 15 点 COMSOL 对比
- [x] COMSOL 偏差收敛到 < 5%：中心点 3.77%，15 点最大 4.927%

## 阶段 4 — 动力代表算例 ✅

- [x] 10x10 Newmark pilot：401 步、40 ms、峰值 -4.4995 mm、f₁=52.20 Hz
- [x] 30x30 模态降阶（8阶）：峰值 -4.4279 mm、捕获比 1.00037
- [x] 模态阶数敏感性（4/6/8/12/16 阶）：8阶已收敛
- [ ] 可选：阻尼比敏感性（0%/0.5%/0.8%/1.5%）
- [ ] 可选：30x30 全量 Newmark 夜间长任务对照

## 阶段 4.5 — 汇报材料 ✅

- [x] `reports/2026-05-22-progress/` 含 Word + 15 张图
- [x] `reports/2026-05-22-dynamic/` 含 5 张图
- [x] `reports/2026-05-22-modal30x30/` 含 6 张图
- [x] `reports/2026-05-22-modal-sensitivity/` 含 8 张图
- [x] `latex-report/main.tex` LaTeX 组会汇报（11页 PDF）

## 阶段 5 — 版本一收尾（补充验证 + 多边界条件）🔲

> 目标：把版本一（纯 FG 无孔隙）的数据做完整，为论文 Section 4/5 提供充足支撑

- [ ] 非 U 分布 COMSOL 验证：选 V 和 X 各跑一组 10 层 CSV 分层验证（脚本已支持 `FG_COMSOL_LAYER_CSV`）
- [ ] 补充 CFCF 边界条件：扩展 `generate_cases.py` 支持 CFCF，跑 U/X 两种 FG × 5 个 Vf（Case A）
- [ ] CFCF 的 COMSOL 对照（至少 1 个代表工况）
- [ ] 整理 `汇报格式-MatlabComsol仿真记录.docx` 中已有的多边界条件逐层温差数据，纳入仓库 `comsol/results/`
- [ ] 可选：阻尼比敏感性（0%/0.5%/0.8%/1.5%），为动力部分论文图补充

## 阶段 6 — 版本二核心：含孔隙 FG-MEE 🔲

> 目标：实现论文核心创新——孔隙效应，预计 150 组主算例
> 参考：`建模思路_版本二_含孔隙FG-MEE板.docx`

### 6.1 孔隙材料模块实现

- [ ] 在 `materials/` 新增 `porosity_correction.m`，实现三种孔隙分布修正：
  - 模式 I（均匀）：`P_eff = P_dense × (1 − e₀)`
  - 模式 II（非均匀，中心富集）：`P_eff = P_dense × [1 − e₀(1 − 2|z|/h)]`
  - 模式 III（对数非均匀）：`P_eff = P_dense − (e₀/2)ln(1−2|z|/h) × P_mix`
- [ ] 修改 `build_layer_materials.m`：接受 `porosity_mode` 和 `e0` 参数
- [ ] 单元测试：e₀=0 时结果与无孔隙完全一致

### 6.2 参数化算例扩展

- [ ] 扩展 `generate_cases.py`：新增 e₀ 和孔隙分布模式参数
- [ ] 设计参数空间：2种FG(U,X) × 5个e₀(0,0.1,0.2,0.3,0.4) × 3种孔隙模式 × 5个Vf₀(0.1,0.3,0.5,0.7,0.9) = 150组
- [ ] 新增 `run_batch_static_porous.m`：循环 Case A/B/C，输出 `output/results_static_porous.csv`
- [ ] CFFF 为主、CFCF 为辅

### 6.3 含孔隙 COMSOL 验证

- [ ] 含孔隙分层模型的 COMSOL 建模（只需修改各层材料参数值）
- [ ] 选取 2-3 个代表工况对比，误差 < 5%

### 6.4 含孔隙动力代表算例

- [ ] 选取 e₀=0.2 / U / Vf0.5 作为动力代表工况
- [ ] 模态降阶 + 频率退化分析

## 阶段 7 — 论文撰写 🔲

> 目标：完成 SCI 四区论文初稿
> 拟题：Parametric simulation of porous FG-MEE plates under thermo-magneto-electro-elastic full coupling

- [ ] 建立 `paper/` 目录结构
- [ ] Section 1 Introduction：MEE背景 + 孔隙问题 + 全耦合温度场研究空白
- [ ] Section 2 Theory：MEE本构 + FG分布 + 孔隙等效模型 + FOSD位移场
- [ ] Section 3 FEM Implementation：八节点板壳 + 含孔隙材料积分适配
- [ ] Section 4 Validation：网格收敛 + MATLAB vs COMSOL（无孔隙 + 含孔隙）
- [ ] Section 5 Results：
  - 5.1 孔隙率对挠度的影响（三种载荷）
  - 5.2 孔隙分布模式对比
  - 5.3 孔隙率-体积分数交互效应
  - 5.4 变形诱导温度场的孔隙率敏感性
  - 5.5 磁电转化效率的参数依赖性
  - 5.6 动态响应代表性分析
  - 5.7 MATLAB-COMSOL 汇总
- [ ] Section 6 Conclusions
- [ ] 图表整理（预计 15-20 张图 + 5-8 个表）
- [ ] 投稿目标期刊调研

---

## 总体进度概览

| 阶段 | 状态 | 说明 |
|------|------|------|
| 1 冒烟测试 | ✅ 完成 | MATLAB 求解器入库并跑通 |
| 2 参数化主算例 | ✅ 完成 | 135组 + reduced Qd修正 |
| 2.5 耦合验证 | ✅ 完成 | 6/6 pass |
| 3 COMSOL验证 | ✅ 完成 | U/Vf0.6/CFFF，误差<5% |
| 4 动力算例 | ✅ 完成 | 模态降阶+敏感性 |
| 4.5 汇报材料 | ✅ 完成 | LaTeX+Word+图表 |
| 5 版本一收尾 | 🔲 进行中 | 多边界+非U验证 |
| 6 含孔隙扩展 | 🔲 待启动 | 论文核心创新 |
| 7 论文撰写 | 🔲 待启动 | SCI四区目标 |
