# Devil's Advocate Report — Checkpoint 2

## Verdict: REVISE

## Critical Issues (Blocks Progression)

No critical issues identified. The synthesis avoids claiming completed electric/magnetic closure and explicitly conditions the interaction contribution on future data, so the current argument is not fatally invalid. Progression is acceptable only after the major issues below are converted into executable gates.

## Major Issues

### 1. The 1% rule can be gamed by the denominator

- **Type:** Method / Measurement.
- **Location:** Theme 2 and proposed validation chain.
- **Problem:** A single relative-error threshold is unstable when the reference displacement or potential is near zero. It also says nothing about sign agreement, absolute scale, or mesh error.
- **Impact:** A result may fail despite negligible absolute error, or pass while both solvers share a large discretization bias.
- **Recommendation:** Pre-register the reference denominator, add a near-zero absolute tolerance, require sign agreement, and report mesh-change and solver-residual indicators alongside relative error.

### 2. “Independent COMSOL” is asserted as a goal but not operationally proven

- **Type:** Method / Evidence.
- **Location:** Theme 2 and Gap 1.
- **Problem:** The synthesis does not yet state which artifacts demonstrate that geometry, material tensors, loads, and post-processing were rebuilt independently rather than imported from the MATLAB/predecessor path.
- **Impact:** A hostile reviewer can reclassify the whole validation as correlated implementation agreement.
- **Recommendation:** Require a COMSOL provenance bundle containing model tree screenshot/export, equation and material-component mapping, mesh statistics, solver settings, output-coordinate definition, and raw table export. Shared numerical outputs may be compared; shared assembled matrices or post-processing scripts may not be used to establish independence.

### 3. The proposed interaction contribution is vulnerable to post hoc discovery

- **Type:** Bias / Research design.
- **Location:** Theme 4 and Knowledge Gap 3.
- **Problem:** With hundreds of combinations, it is easy to select an visually interesting curve after seeing the results. No primary interaction contrast or effect threshold has been frozen.
- **Impact:** Apparent novelty may be a multiple-comparison or visualization artifact.
- **Recommendation:** Freeze primary factors, one primary output per chain, a hierarchical main-effect-then-interaction analysis, and a minimum effect threshold above combined numerical uncertainty before running the full matrix.

### 4. The novelty boundary relies heavily on abstract-level evidence

- **Type:** Evidence / Selection bias.
- **Location:** Theme 1 and novelty gap conclusion.
- **Problem:** Only 2/23 sources were checked against local original full text. The targeted search is recent-heavy and Semantic Scholar degraded. Abstracts can omit relevant validation details or negative findings.
- **Impact:** The statement that a specific same-denominator three-way validation map is absent remains provisional.
- **Recommendation:** Before manuscript submission, acquire and inspect the 5 direct novelty-boundary papers at minimum: Zhang 2022, Zhao 2024, Ellouz 2023, Tarkashvand 2025, and Gong 2025. Retain the phrase “not found in the present targeted search” until then.

### 5. The synthesis mixes macro plates/shells with micro/nano studies

- **Type:** Scope / Generalizability.
- **Location:** Theme 4 and literature matrix.
- **Problem:** Nonlocal strain-gradient micro/nano models and macroscale shell models do not share the same governing assumptions.
- **Impact:** Cross-scale citation density can create false confidence that a macroscale interaction is established.
- **Recommendation:** Use micro/nano papers only to delimit topic saturation; exclude them from quantitative parameter selection and from the weight assigned to macro-scale response claims.

## Minor Issues

- The magnetic “200 A” load needs an exact COMSOL boundary-variable and sign definition; current wording is physically ambiguous.
- The curved-shell “center” must be frozen in parametric and global coordinates before any comparison.
- Scaling 2 mm results to 1.0 or 0.5 mm is permissible only after linearity is verified at at least two independently solved amplitudes.
- A 10% rerun audit should be stratified by geometry, load chain, gradient and porosity, not sampled uniformly from rows.
- The source corpus is concentrated in computational publications and may under-represent null or failed simulations.

## Observations

- The strongest part of the project is not the number of simulated cases but its ability to make disagreements traceable to units, signs, tensors, coordinates, mesh or solver settings.
- Publishing failed high-memory or non-convergent cases with explicit exclusion rules could strengthen reproducibility if it does not distract from the primary result.

## Strongest Counter-Argument

> “This is an engineering verification exercise around a mature FG-MEE plate/shell model, not a scientific contribution: the geometric and material factors are already studied, the supposed interaction is not pre-registered, the COMSOL implementation is not yet proven independent, and there is no experiment.”

The paper can answer this only if it demonstrates a pre-specified, non-additive interaction or a defensible design window after independent cross-platform closure. Otherwise it must be framed honestly as a rigorous verification/reproducibility paper.

## What's Missing

- Independent COMSOL files and raw exports for electric, magnetic and inverse sensing.
- A frozen error metric with near-zero handling.
- Full-text inspection of the five closest novelty competitors.
- A primary interaction contrast and uncertainty-based minimum effect size.
- Experimental evidence; if unavailable, an explicit numerical-only scope statement.

## Stress Test Results

| Test | Result |
|---|---|
| Remove strongest source — does argument hold? | Partly. Object maturity holds; quantitative validation scale weakens materially without Zhang 2026. |
| Flip the research question — is opposing view credible? | Yes. The null view that only main effects and implementation differences exist is credible. |
| Apply to different context — does finding generalize? | No. Micro/nano and macroscale structures cannot be pooled quantitatively. |
| “So what?” — is significance justified? | Not yet. It becomes justified only after independent closure and a pre-specified interaction/design result. |

## Frame-Lock Check

The analysis assumes that a small cross-platform difference is the best proxy for correctness. Two solvers can agree because they share the same constitutive assumption or boundary idealization. The manuscript must therefore call the result “cross-platform numerical consistency,” not physical truth.

