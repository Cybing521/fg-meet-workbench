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
