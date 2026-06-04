# Paper workspace

Working title: **Parametric simulation of porous FG-MEE plates under thermo-magneto-electro-elastic full coupling**

This directory starts Phase 7. The data layer is now sufficient for a complete first manuscript draft. Non-U and CFCF COMSOL validation rows have passed; porous COMSOL validation has been run and should be discussed as a model-formulation review item in Section 4.

## Data inventory

| Dataset | Scale | Source |
|---------|-------|--------|
| Non-porous CFFF static sweep | 135 rows, 5 FG modes x 9 Vf0 x 3 load cases | `output/results_static.csv` |
| CFCF boundary comparison | 30 rows, U/X x 5 Vf0 x 3 load cases | `output/results_static_cfcf.csv` |
| Porous static sweep | 390 rows, 130 cases x 3 load cases | `output/results_static_porous.csv` |
| Non-porous dynamic representatives | U/V/X/O/P, 10x10 full Newmark; U/Vf0=0.6 30x30 modal reduction | `reports/2026-05-27-dynamic-fg-sweep/`, `reports/2026-05-22-modal30x30/` |
| Porous dynamic pilot | U/Vf0=0.5/e0=0.2/Even, 10x10 full Newmark | `output/dynamic_porous_U_Vf50_e20_Even_10x10_summary.csv` |
| COMSOL validation | U/Vf0=0.6/CFFF baseline passed; V/X and CFCF passed; porous representatives solved but need orthotropic/anisotropic COMSOL material review | `comsol/results/manual_validation_plan.csv`, `comsol/results/validation_summary_generated.csv`, `reports/2026-06-04-porous-comsol-model-review/README.md` |

## Manuscript map

| Section | Purpose | Primary evidence |
|---------|---------|------------------|
| 1 Introduction | Motivate FG-MEE plates, porosity, and full thermo-magneto-electro-elastic coupling | Literature review and problem gap |
| 2 Theory | Constitutive equations, FG law, porosity correction, plate kinematics | `materials/` and solver formulation |
| 3 FEM implementation | Eight-node plate/shell implementation, layer integration, coupled DOF handling | `matlab/meet-fem-core/`, `run_meet_static.m` |
| 4 Validation | MATLAB-COMSOL comparison and mesh strategy | `comsol/results/`, `comsol/docs/manual-validation-workflow.md` |
| 5 Static parametric results | Non-porous baseline, boundary effects, porous sensitivity | `reports/2026-05-28-porous-static/`, `reports/2026-06-01-cfcf-static/` |
| 6 Dynamic representative results | Newmark pilot, modal reduction, damping/mode sensitivity | `reports/2026-05-22-modal-sensitivity/`, `reports/2026-06-01-porous-dynamic/` |
| 7 Conclusions | Summarize design rules and limitations | Consolidated findings |

## First-draft order

1. Write Methods first: Sections 2 and 3 are mostly stable and do not depend on further COMSOL model review.
2. Draft Section 5 from the completed static reports.
3. Draft Section 6 from dynamic reports, using the porous 10x10 run as a pilot result.
4. Fill Section 4 with the existing U/Vf0=0.6 baseline plus the new V/X and CFCF passing rows; describe the porous COMSOL deviation as a validation-model limitation tied to the current isotropic solid surrogate (`E1`, `v12`, `Density` only).
5. Write Introduction and Conclusions last, once the result narrative is fixed.
