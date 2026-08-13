# Ethics Review Report

## Verdict: CONDITIONAL

## Dimension Assessment

| Dimension | Status | Notes |
|---|---|---|
| AI Disclosure | pass | Disclosure identifies AI-assisted search, verification, synthesis and drafting; final responsibility remains human. |
| Attribution Integrity | pass | No fabricated reference or DOI mismatch found; claim strength is generally aligned with full-text versus abstract access. |
| Dual-Use Screening | pass | Risk level: Low. Structural multiphysics simulation has no specific harm-enabling operational content in this report. |
| Fair Representation | pass | No human community or vulnerable population is studied; competing literature is represented without disparagement. |
| Data Ethics | warn | Local simulation artifacts are used ethically, but final data/model availability and licensing terms are not stated. |
| Conflict of Interest | warn | Funding, author relationship to predecessor work, and institutional interests are not disclosed in the draft. |
| Human Subjects Ethics | N-A | IRB level: N-A. No human subjects, personal data or identifiable records are analyzed. |

## Issues Found

### Critical (Blocks Delivery)

No critical issues.

### Conditional (Must Fix)

- Add explicit Funding and Conflict of Interest statements, including whether the researcher belongs to the predecessor research group or uses inherited code.
- Add Data and Code Availability statements specifying which MATLAB scripts, COMSOL models, raw tables and logs can be shared and under what access conditions.
- Before submission, check all journal references against retraction/correction notices and record the date of that check.

### Advisory (Recommended)

- Preserve the current distinction between abstract-level and full-text verification in supplementary material.
- Keep failure logs, but remove workstation-specific personal paths from any public archive.
- Replace any future claim that “all findings were verified” with a scoped statement describing which claims were metadata-, abstract-, table- or full-text-verified.

## AI Disclosure Verification

- [x] Disclosure statement present: Yes
- [x] Scope accurate: Yes
- [x] Limitations noted: Yes, although final human approval should be stated again at submission

## Reference Integrity Check

- Total references cited: 16
- Systematically checked in this review: 9 (56.3%)
- Full-text/table checked: Zhang et al. 2026; Zhao 2023
- DOI, official metadata and abstract-scope checked: Zhang 2022; Zhao 2024; Ellouz 2023; Tarkashvand 2025; Brischetto 2025; Gong 2025; Tassi 2022
- Issues found: No fabricated or mismatched reference. The main limitation is access depth, not source identity.
- Retraction/correction status: Not yet systematically checked; required before submission.
- Self-citation rate: Cannot be determined until the manuscript author list is frozen.

## Responsible Use Statement

No additional responsible-use statement is required at the current low risk level. Public release should nevertheless exclude personal workstation paths and proprietary software license information.

## Ethics Clearance Notes

The project is ethically low risk and does not require human-subjects review. The conditional verdict concerns transparency and reproducibility rather than participant harm. Once funding/COI, data/code availability and retraction-status checks are added, the report can be ethically cleared.

## Ethics Decision Log

| Item | Verdict | User decision | Reasoning |
|---|---|---|---|
| Funding/COI and inherited-code relationship disclosure | CONDITIONAL | Pending Phase 6 fix | Required for transparent attribution and bias assessment |
| Data/code availability and license scope | CONDITIONAL | Pending Phase 6 fix | Required to make reproducibility claims precise |
| Retraction/correction status check | CONDITIONAL | Pending pre-submission check | Database-level check not completed in this stage |

