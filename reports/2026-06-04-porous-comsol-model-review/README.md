# Porous COMSOL model construction review

## Direct answer

The porous discrepancy is not best treated as a load-method problem. The current batch model already uses the validated Case A force-area route: top surface load `FperArea = [0, 0, -15000] N/m^2`. The evidence points instead to the porous COMSOL solid surrogate being too simple for the porous MATLAB plate model.

The specific modeling gap is that `tools/comsol/RunElasticCfffValidation.java` reads the 10-layer CSV but assigns only `E1`, `v12`, and `Density` to a COMSOL isotropic elastic material. The MATLAB input and layer CSV contain the fuller plate material row (`E1/E2/G12/G13/G23`, coupling and thermal terms). The simplification still passes for non-porous/non-U checks, but after porosity softening it produces a systematic extra-flexible response.

## Review result

- Best porous 15-point maximum error: `6.594%`.
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
| Solid material formulation | Needs change | Current COMSOL driver consumes only `E1`, `v12`, `Density` and treats each layer as isotropic. |

## Next implementation path

The next real fix is to add an orthotropic/anisotropic material mode to the COMSOL Java driver and rerun the three porous validation rows. That mode should assign at least `E1`, `E2`, `G12`, `G13`, `G23`, `v12`, `v23`, and `Density` per layer. If the target is full thermo-magneto-electro-elastic validation rather than elastic deflection validation, the mapped coupling/thermal constants must also be moved out of the CSV-only documentation path and into the COMSOL physics definition.

Until that orthotropic COMSOL rerun is complete, the paper/report wording should remain: non-U and CFCF are validated within 5%; porous rows are solved but require COMSOL model-formulation review.

## Generated files

- `data/point_bias_summary.csv`
- `data/material_parity_summary.csv`
- `data/comsol_material_usage.csv`
