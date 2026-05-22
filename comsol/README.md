# COMSOL 验证模块

与仓库内 **MATLAB MEET 全耦合求解器** 对照，验证板壳有限元在 FG-MEE 问题上的精度（目标：关键量相对偏差 &lt; 5%）。

## COMSOL 在本项目中的职责

| 项目 | 说明 |
|------|------|
| 不算全参数扫描 | 仅对代表工况做对照，不做 45×3 组批量主算例 |
| 几何 | 300 mm × 300 mm × 6 mm 方板，与 `templates/` 一致 |
| 分层材料 | 厚度 10 层，每层参数与 `cases/*.txt` 的 MATERIAL 段一致 |
| 全耦合等效 | 固体+传热模块无法直接做“变形→温差”；采用 **压电模块等效**（热应力系数→压电系数，热容→介电常数，输出电场→温差） |
| 网格 | 建议 50×50×10 六面体；与 `comsol/docs/mesh-convergence.md` 记录一致 |
| 输出 | 位移场；等效“温度/温差”场；与 MATLAB 同坐标点对比 |

## 建议工作流程

1. **从 MATLAB 侧导出分层材料**（可选）  
   ```bash
   python3 tools/export_comsol_layers.py cases/Thermal_CFFF_X_Vf0.5-30x30-10layer.txt
   ```
   生成 `comsol/export/<case>_layers.csv`，在 COMSOL 中逐层赋值。

2. **建立基准模型**  
   - 边界：CFFF（与试点算例一致）  
   - Case A：顶面均布压力 15000 Pa  
   - Case B：上下 ±300 V（或等效应力，见 `comsol/docs/equivalent-loads.md`）  
   - Case C：上下 ±200 A 磁势等效

3. **选点对比**  
   使用 `comsol/data/validation_points.csv` 中的 MATLAB 单元中心与 COMSOL 空间坐标配对（源自课题组历史验证记录）。

4. **记录结果**  
   填写 `comsol/results/validation_log.csv`（模板见同目录）。

## 当前自动化基准（2026-05-22）

已通过本地 COMSOL 6.0 批处理跑通一个弹性对照：

- 工况：U / Vf0.6 / CFFF / Case A，顶面压力 15000 Pa。
- COMSOL 脚本：`tools/comsol/RunElasticCfffValidation.java`。
- MATLAB 对比脚本：`tools/compare_comsol_meet_validation.py`。
- 输出：`output/comsol_elastic_cfff_U_Vf06_layered_csv_sweep7_mesh4_points.csv`、`comsol/results/validation_points_U_Vf06_elastic.csv`、`comsol/results/validation_log.csv`。

当前通过结果：中心点 p8 为 MATLAB -2.12752 mm、COMSOL -2.20774 mm，相对误差 3.77%；15 点最大相对误差 4.927%，平均 3.51%。关键处理包括：

- MATLAB reduced `Qd` 先按节点约束标志还原为完整 5-DOF 节点位移，再取对比点。
- COMSOL 使用 10 层 CSV 分域材料 + 扫掠 quad/hex 网格（mesh size 4，每个材料层 7 个扫掠单元）替代自由四面体网格。
- `ForceArea` 与 `FollowerPressure` 在该线性小变形算例中结果一致；偏差主要来自网格/单元类型一致性。

后续非 U 分布算例可复用 `FG_COMSOL_LAYER_CSV` 指向对应 `comsol/export/*_layers.csv`。

批处理运行前，COMSOL Security Preferences 需要允许方法/Java 库访问文件系统（`File system access = All files`），否则 `.class` 批处理会在 recovery 文件写入阶段失败。

## 目录

```
comsol/
├── README.md                 # 本文件
├── docs/
│   ├── equivalent-modeling.md   # 等效热耦合说明
│   ├── equivalent-loads.md      # 电/磁载荷在 COMSOL 中的处理
│   └── mesh-convergence.md      # 网格收敛记录表
├── data/
│   └── validation_points.csv    # 对比点坐标
├── export/                      # 脚本导出的分层材料（gitignore 可选）
└── results/
    └── validation_log_template.csv
```

## 与 MATLAB 的分工（摘要）

- **MATLAB**：主算例、参数扫描、论文主图主表。  
- **COMSOL**：代表性工况独立验证、审稿人可复现的商用软件对照。

详细任务见仓库根目录 [TODO.md](../TODO.md) 阶段 3。
