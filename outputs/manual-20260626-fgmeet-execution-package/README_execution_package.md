# FG-MEET 执行材料压缩包说明

生成日期：2026-06-26

## 文件内容

1. `fg_meet_execution_plan.pdf`
   - 正式执行方案。
   - 说明 MATLAB 正确执行入口、目录要求、单工况运行方式和注意事项。

2. `fg_meet_execution_plan.tex`
   - 正式执行方案的 LaTeX 源文件。

3. `fg_meet_matlab_recording_script.pdf`
   - 录屏演示脚本。
   - 按镜头顺序说明 MATLAB 中要打开什么、输入什么命令、预期看到什么。
   - 不包含代码实现讲解，只讲执行顺序。

4. `fg_meet_matlab_recording_script.tex`
   - 录屏演示脚本的 LaTeX 源文件。

## 建议使用方式

- 发给对方确认执行方式：优先使用 `fg_meet_execution_plan.pdf`。
- 自己录制演示视频：使用 `fg_meet_matlab_recording_script.pdf`。
- 需要修改文字或路径：编辑对应 `.tex` 文件后用 XeLaTeX 重新编译。

## 关键结论

正确入口是从交付包根目录运行：

```matlab
setup_paths
run('run_phase1_static_elastic.m')
```

或者指定输入文件运行：

```matlab
paths = setup_paths;
caseFile = fullfile(paths.cases, 'Thermal_CFFF_U_Vf0.6-30x30-10layer.txt');
result = run_meet_static(caseFile, 'elastic');
```

不要直接在 `materials` 目录下零参数运行 `build_layer_materials.m`。
