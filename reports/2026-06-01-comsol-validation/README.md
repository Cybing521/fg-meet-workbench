# COMSOL automated validation update (2026-06-01)

This report records actual COMSOL 6.0 `comsolbatch` runs for the previously CSV-ready Phase 5.1, Phase 5.4, and Phase 6.3 validation targets. These are not workflow placeholders: each row below was solved in COMSOL using the exported 10-layer material CSV.

## Model setup

- Geometry: 300 mm x 300 mm x 6 mm plate, 10 through-thickness material domains.
- Material assignment: per-layer `E1`, `v12`, and `Density` from the corresponding CSV.
- Physics: 3D solid mechanics elastic validation, top force-area load `15000 Pa`.
- Mesh: swept quad/hex mesh. The default comparison uses mesh size 4 and 7 swept elements per material layer; CFCF was also run with mesh size 3 and 10 swept elements per layer.
- MATLAB reference: corresponding 30x30 MEET elastic `.mat` files and case input node coordinates.

## Best results by target

| Target | Boundary | COMSOL mesh | Center error | 15-point max error | Status |
|--------|----------|-------------|--------------|--------------------|--------|
| V/Vf0=0.6 | CFFF | mesh4/sweep7 | 2.959% | 4.190% | pass |
| X/Vf0=0.6 | CFFF | mesh4/sweep7 | 2.839% | 4.060% | pass |
| X/Vf0=0.1 | CFCF | mesh3/sweep10 | 3.831% | 3.831% | pass |
| U/Vf0=0.5/e0=0.2/Even | CFFF | mesh4/sweep7 | 4.980% | 6.003% | center pass, 15-point pending |
| U/Vf0=0.5/e0=0.3/Even | CFFF | mesh4/sweep7 | 5.598% | 6.594% | outside 5% |
| X/Vf0=0.5/e0=0.2/Even | CFFF | mesh4/sweep7 | 4.349% | 5.434% | center pass, 15-point pending |

## Interpretation

The non-U CFFF and CFCF boundary checks are now validated by COMSOL within the 5% criterion. The porous checks are real COMSOL solves, but the current 3D solid elastic surrogate remains slightly outside the 15-point 5% criterion for the selected porous representatives. The deviation is systematic near the larger-deflection free-edge points; refining the COMSOL swept mesh did not reduce the porous discrepancy, so the next step is model-formulation review rather than another blind mesh refinement.

## Files

- `comsol/results/validation_summary_generated.csv`: all automated COMSOL runs.
- `comsol/results/validation_log_generated.csv`: validation log rows.
- `comsol/results/validation_points_*_layered_csv_*.csv`: 15-point comparison tables.
- `tools/compare_comsol_validation_general.py`: generic MATLAB-vs-COMSOL point comparison script.
- `tools/comsol/RunElasticCfffValidation.java`: parameterized COMSOL batch driver.
