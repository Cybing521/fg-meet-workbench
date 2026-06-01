# 含孔隙动力代表算例（2026-06-01）

本报告整理 `run_dynamic_porous_representative.m` 的 10x10 完整 Newmark pilot。工况为 U / Vf0=0.5 / e0=0.2 / Even / CFFF / Case A step load，作为 30x30 模态降阶前的流程验证与趋势参考。

## 关键结果

- 静力中心挠度：-2.4558 mm。
- 动态峰值中心挠度：-5.2218 mm，峰值时刻 27.80 ms。
- 超调比：2.126。
- 最大层温差：6.5016 K。
- 频率求解状态：ok。

## 文件

- `data/dynamic_porous_U_Vf50_e20_Even_10x10_summary.csv`: 动力摘要。
- `data/dynamic_porous_U_Vf50_e20_Even_10x10_timeseries.csv`: 中心挠度与层温差时程。
- `figures/`: 摘要表、中心挠度时程、层温差时程。
