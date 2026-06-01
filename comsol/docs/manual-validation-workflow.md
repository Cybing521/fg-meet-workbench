# COMSOL validation workflow

This how-to records the COMSOL validation workflow for Phase 5.1, Phase 5.4, and Phase 6.3. The validation has now been run through `comsolbatch` for all listed targets; the GUI steps remain useful only when a visual recording or manual model inspection is needed.

## Scope

Use this workflow for:

| Phase | Target | Status |
|------|--------|--------|
| 5.1 | Non-U CFFF validation, V/X at Vf0=0.6 | COMSOL batch passed |
| 5.4 | CFCF boundary validation, representative X/Vf0=0.1 | COMSOL batch passed on refined mesh |
| 6.3 | Porous CFFF validation, U/X porous representatives | COMSOL batch run; porous model needs review |

The target list and MATLAB reference center deflections are tracked in `comsol/results/manual_validation_plan.csv`. The generated validation tables are summarized in `reports/2026-06-01-comsol-validation/README.md`.

## Prepared CSV files

| Target | Layer CSV |
|--------|-----------|
| V/Vf0=0.6/CFFF | `comsol/export/nonU/FG_V_Vf0.6_layers.csv` |
| X/Vf0=0.6/CFFF | `comsol/export/nonU/FG_X_Vf0.6_layers.csv` |
| X/Vf0=0.1/CFCF | `comsol/export/Thermal_CFCF_X_Vf0.1-30x30-10layer_layers.csv` |
| U/Vf0=0.5/e0=0.2/Even/CFFF | `comsol/export/porous/Porous_U_Vf0.5_e20_Even_layers.csv` |
| U/Vf0=0.5/e0=0.3/Even/CFFF | `comsol/export/porous/Porous_U_Vf0.5_e30_Even_layers.csv` |
| X/Vf0=0.5/e0=0.2/Even/CFFF | `comsol/export/porous/Porous_X_Vf0.5_e20_Even_layers.csv` |

## Procedure

1. Open the validated COMSOL model from the U/Vf0=0.6/CFFF baseline.
2. Keep the validated solid geometry, 10 material domains, swept quad/hex mesh, mesh size 4, and 7 swept elements per material layer.
3. For each validation target, open the corresponding CSV and assign row 1 through row 10 to material layers 1 through 10.
4. Map the CSV columns to the material constants used in the current model: `E1`, `E2`, `v12`, `v23`, `G12`, `G13`, `G23`, `d31`, `d32`, `q31`, `q32`, `g33`, `k33`, `r33`, `A1`, `A2`, `PyroE`, `PyroM`, `Cv`, `HC`, and `Density`.
5. Set the boundary condition:
   - CFFF for Phase 5.1 and Phase 6.3.
   - CFCF for Phase 5.4; the CSV only changes material properties, so the boundary must be changed in the COMSOL selections.
6. Apply Case A loading: top-surface pressure `15000 Pa`. Keep the sign convention consistent with the baseline validation.
7. Solve the stationary study.
8. Evaluate z-displacement at the 15 coordinates in `comsol/data/validation_points.csv`.
9. Compare against MATLAB values and append the result to `comsol/results/validation_log.csv`. Use `comsol/results/validation_log_template.csv` if creating a new row set.

## Acceptance criteria

- Center-point relative error is below 5%.
- 15-point maximum relative error is below 5%, or any outlier is explained by mesh interpolation near constrained edges.
- Record the COMSOL mesh mode, mesh size, swept layers, material CSV path, and boundary condition in the validation log.

## Notes

- The CSV files are material-layer inputs only. Boundary conditions and loads are still set in COMSOL.
- For CFCF, the representative X/Vf0=0.1 case is selected because it has the strongest elastic CFCF/CFFF deflection suppression in the MATLAB sweep.
- The porous reference values in the plan file come from `output/results_static_porous.csv`; the current exact values differ slightly from earlier rounded notes.
