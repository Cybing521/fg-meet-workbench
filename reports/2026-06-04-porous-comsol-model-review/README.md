# Porous COMSOL model construction review

## Direct answer

The porous discrepancy is not best treated as a load-method problem. The current batch model already uses the validated Case A force-area route: top surface load `FperArea = [0, 0, -15000] N/m^2`. The new orthotropic rerun also keeps that physical load unchanged, and it still misses the 5% target.

The driver now has an explicit `FG_COMSOL_SOLID_MODEL=orthotropic` path that sets COMSOL Solid Mechanics to `SolidModel=Orthotropic` and assigns `E1/E2/v12/v23/G12/G13/G23/Density` from each porous layer CSV. That experiment makes COMSOL slightly more flexible, so the remaining mismatch is deeper than the old isotropic material shortcut.

## Review result

- Best porous 15-point maximum error: `6.594%`.
- Orthotropic porous 15-point maximum error: `7.351%`; center errors span `5.905%`--`6.626%`.
- Refined porous mesh maximum error: `7.268%`; refinement increases the discrepancy, so this is not a mesh-density fix.
- Non-porous/non-U reference maximum error remains within criterion: `4.927%`.
- Porous COMSOL/MATLAB mean displacement ratio is `1.04279`--`1.05549`; COMSOL is consistently more flexible.
- MATLAB case MATERIAL rows and exported porous layer CSVs match within formatted input precision; maximum case-vs-CSV relative difference is `0.035%`.

## Pointwise bias summary

| Case | Run | Center error | Max error | Mean ratio C/M | Max-error point |
|------|-----|--------------|-----------|----------------|-----------------|
| U/Vf0=0.5/e0=0.2/Even | mesh4/sweep7 | 4.980% | 6.003% | 1.04881 | p15 (0.25,0.25) |
| U/Vf0=0.5/e0=0.3/Even | mesh4/sweep7 | 5.598% | 6.594% | 1.05549 | p15 (0.25,0.25) |
| X/Vf0=0.5/e0=0.2/Even | mesh4/sweep7 | 4.349% | 5.434% | 1.04279 | p15 (0.25,0.25) |
| U/Vf0=0.5/e0=0.2/Even | orthotropic mesh4/sweep7 | 6.376% | 7.066% | 1.06383 | p15 (0.25,0.25) |
| U/Vf0=0.5/e0=0.3/Even | orthotropic mesh4/sweep7 | 6.626% | 7.351% | 1.06634 | p5 (0.25,0.05) |
| X/Vf0=0.5/e0=0.2/Even | orthotropic mesh4/sweep7 | 5.905% | 6.570% | 1.05909 | p15 (0.25,0.25) |
| U/Vf0=0.5/e0=0.2/Even | mesh3/sweep10 | 6.042% | 6.756% | 1.06098 | p14 (0.20,0.25) |
| U/Vf0=0.5/e0=0.3/Even | mesh3/sweep10 | 6.557% | 7.268% | 1.06671 | p13 (0.15,0.25) |
| X/Vf0=0.5/e0=0.2/Even | mesh3/sweep10 | 5.398% | 6.172% | 1.05487 | p14 (0.20,0.25) |

## Load-method check

The load route is:

1. MATLAB Case A uses `LoadScale = -15000` as a distributed mechanical load.
2. COMSOL uses `BoundaryLoad` with `LoadType = ForceArea` and `FperArea = [0, 0, -15000[N/m^2]]` on the top face.
3. If the load magnitude or sign were the primary issue, the already-passing non-U/CFCF rows would show the same failure pattern. They do not.

A post-hoc load rescaling could numerically reduce the porous displacement error because the model is linear, but that would only calibrate away the symptom. It would not be a defensible validation result.

## Construction review checklist

| Item | Status | Evidence |
|------|--------|----------|
| Layer geometry | OK | Ten stacked domains, z ranges from the layer CSV. |
| Layer material CSV export | OK | MATERIAL block and CSV match within printed precision. |
| Boundary condition | OK | CFFF/CFCF selection logic is explicit in Java driver; CFCF refined row passes. |
| Load method | OK for Case A | Uses force-area load with MATLAB pressure magnitude. |
| Mesh density | Not root cause | Refined porous mesh increases error. |
| Orthotropic material formulation | Implemented, not sufficient | `FG_COMSOL_SOLID_MODEL=orthotropic` consumes `E1/E2/v12/v23/G12/G13/G23/Density`, but the three porous rows still exceed 5%. |

## Next implementation path

The next real fix is a formulation review rather than a load calibration. The highest-value checks are: confirm the COMSOL orthotropic axis convention and Poisson reciprocity, compare the MATLAB plate stiffness terms against the 3D solid constitutive matrix COMSOL is solving, and decide whether this validation should use a layered shell/plate representation instead of stacked 3D solid domains. A full anisotropic `D` matrix mode is only useful after deriving the correct 6x6 elastic matrix from the MATLAB effective layer constants.

The paper/report wording should therefore remain conservative: non-U and CFCF are validated within 5%; porous rows are solved in COMSOL, including an orthotropic rerun, but they remain a model-formulation review item.

## Generated files

- `data/point_bias_summary.csv`
- `data/material_parity_summary.csv`
- `data/comsol_material_usage.csv`
- `comsol/results/validation_summary_porous_orthotropic_experiment.csv`
