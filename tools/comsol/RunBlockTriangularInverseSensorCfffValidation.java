import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Locale;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/**
 * Independent ten-layer COMSOL four-field inverse-sensing validation.
 *
 * <p>The stationary system contains four sets of finite-element unknowns:
 * the three-component displacement field {@code u}, electric scalar potential
 * {@code phiN}, magnetic scalar potential {@code psiN}, and reciprocal
 * temperature field {@code tempN}.  The scalar fields are implemented as
 * separate Weak Form PDE interfaces.  Mechanical feedback is supplied through
 * a domain External Stress feature, while strain, electric, magnetic, thermal,
 * and magnetoelectric terms appear in the sensor equations.  The official
 * comparison mode is block triangular, matching MATLAB's simultaneous
 * {@code u,T} solve followed by the open-circuit {@code phi,psi} block: the
 * sensing potentials do not feed back into the mechanical-thermal block.
 * Consequently the reported potentials are solution fields from the same
 * stationary algebraic system; they are not reconstructed from strain after
 * the solve.</p>
 *
 * <p>Electric and magnetic open-circuit boundaries and thermal insulation are
 * the natural zero-flux boundaries of their weak forms.  A single point value
 * is fixed for each scalar potential solely to remove its additive gauge.  The
 * reciprocal temperature equation is the same local algebraic capacity law
 * used by the MATLAB element and therefore contains no artificial heat
 * diffusion or thermal boundary flux.</p>
 */
public class RunBlockTriangularInverseSensorCfffValidation {
    private static final double L = 0.300;
    private static final double W = 0.300;
    private static final double H = 0.006;
    private static final int PHYSICAL_LAYER_COUNT = 10;
    private static final double LAYER_THICKNESS = H / PHYSICAL_LAYER_COUNT;

    private static final double YOUNG = 1.206e11;
    private static final double NU = 0.3398;
    private static final double RHO = 5600.0;
    private static final double D31 = -5.404e-11;
    private static final double D32 = -5.404e-11;
    private static final double Q31 = 49.47;
    private static final double Q32 = 49.47;
    private static final double G33 = 9.203e-9;
    private static final double K33 = 1.755e-8;
    private static final double R33 = 7.536e-5;
    private static final double BETA1 = 2.356e6;
    private static final double BETA2 = 2.356e6;
    private static final double PYRO_E = 2.492e-4;
    private static final double PYRO_M = 5.900e-3;
    private static final double HEAT_CAPACITY = 4.252e2;

    /* Scaling affects conditioning only; output variables remain in V, A, K. */
    private static final double PHI_SCALE = 1.0e3;
    private static final double PSI_SCALE = 1.0;
    private static final double TEMP_SCALE = 1.0;
    private static final double ELECTRIC_FLUX_SCALE = 1.0e-2;
    private static final double MAGNETIC_FLUX_SCALE = 5.0e-2;

    private static final double PROBE_PRESSURE_PA = doubleEnv(
        "FG_FOUR_FIELD_PROBE_PRESSURE_PA", 15000.0
    );
    private static final int INPLANE_DIVISIONS = intEnv(
        "FG_FOUR_FIELD_INPLANE_DIVISIONS", 10
    );
    private static final int THICKNESS_DIVISIONS_PER_LAYER = intEnv(
        "FG_FOUR_FIELD_THICKNESS_DIVISIONS", 1
    );
    private static final String OUTPUT_DIR = env(
        "FG_FOUR_FIELD_OUTPUT_DIR",
        new File("outputs/code_closure/comsol_four_field").getAbsolutePath()
    );
    private static final String RUN_TAG = env("FG_FOUR_FIELD_RUN_TAG", "comsol_four_field");
    private static final String RUN_ID = env("FG_FOUR_FIELD_RUN_ID", "missing_run_id");
    private static final String SOURCE_SHA256 = env(
        "FG_FOUR_FIELD_SOURCE_SHA256", "missing_source_sha256"
    );

    private static final double[] TARGET_MM = new double[] {0.5, 1.0, 2.0};
    private static final String METHOD = "sequential_equivalent_four_field_solution";
    private static final String EVIDENCE_TIER = "A_independent_block_triangular_fields";
    private static final double PHYSICS_WEAK_MOMENT_LIMIT = 1.0e-6;
    private static final double SOLVER_CONVERGENCE_LIMIT = 1.0e-5;
    private static final String STATIONARY_RELATIVE_TOLERANCE = "1e-4";
    private static final int SEGREGATED_FIXED_ITERATIONS = 25;
    private static final int FINAL_SOLVER_GROUP_COUNT = 1 + 3 * PHYSICAL_LAYER_COUNT;
    private static final int FIELD_GROUP_COUNT = 4;
    private static final int GROUP_SOLID = 0;
    private static final int GROUP_ELECTRIC = 1;
    private static final int GROUP_MAGNETIC = 2;
    private static final int GROUP_THERMAL = 3;
    private static final int CONVERGENCE_GROUP_ERROR_START = 0;
    private static final int CONVERGENCE_LINEAR_RESIDUAL_START = FIELD_GROUP_COUNT;
    private static int numericalCounter = 0;

    private static final int P_W_MM = 0;
    private static final int P_PHI_SPAN_V = 1;
    private static final int P_PSI_SPAN_A = 2;
    private static final int P_T_AVG_K = 3;
    private static final int P_EX_AVG = 4;
    private static final int P_EY_AVG = 5;
    private static final int P_PHI_BOTTOM_V = 6;
    private static final int P_PHI_TOP_V = 7;
    private static final int P_PSI_BOTTOM_A = 8;
    private static final int P_PSI_TOP_A = 9;
    private static final int P_PRESSURE_PA = 10;
    private static final int P_LAYER_START = 11;
    private static final int P_LAYER_STRIDE = 5;
    private static final int P_LAYER_EX = 0;
    private static final int P_LAYER_EY = 1;
    private static final int P_LAYER_T = 2;
    private static final int P_LAYER_PHI = 3;
    private static final int P_LAYER_PSI = 4;
    private static final int PROBE_SIZE = P_LAYER_START
        + PHYSICAL_LAYER_COUNT * P_LAYER_STRIDE;

    public static Model run() {
        validateConfiguration();
        File outputDirectory = new File(OUTPUT_DIR);
        if (!outputDirectory.exists() && !outputDirectory.mkdirs()) {
            throw new IllegalStateException("Cannot create output directory: " + OUTPUT_DIR);
        }
        clearStaleEvidence(outputDirectory);
        File progressFile = new File(outputDirectory, "comsol_four_field_solver_progress.log");
        if (progressFile.exists() && !progressFile.delete()) {
            throw new IllegalStateException("Cannot replace progress log: " + progressFile);
        }
        ModelUtil.showProgress(progressFile.getAbsolutePath());

        Model model = ModelUtil.create("FourFieldModel");
        model.modelPath(outputDirectory.getAbsolutePath());
        model.label("comsol_four_field_Model.mph");
        configureParameters(model);
        createGeometryAndSelections(model);
        createMaterial(model);
        createSolidMechanics(model);
        createElectricWeakForm(model);
        createMagneticWeakForm(model);
        createThermalWeakForm(model);
        createCoupledVariables(model);
        createMesh(model);
        createStationaryStudy(model);
        validateApiSmoke(model);

        double[] electricOnly = solveChannel(model, 1.0, 0.0, 0.0, "electric");
        double[] magneticOnly = solveChannel(model, 0.0, 1.0, 0.0, "magnetic");
        double[] thermalOnly = solveChannel(model, 0.0, 0.0, 1.0, "thermal");
        String isolationStatus = validateChannelIsolation(
            electricOnly, magneticOnly, thermalOnly
        ) ? "pass" : "fail";

        double[] loadNormalization = solveChannel(
            model, 1.0, 1.0, 1.0, "load_normalization_reference"
        );
        double referenceAbsW = Math.abs(loadNormalization[P_W_MM]);
        if (!(referenceAbsW > 0.0)) {
            throw new IllegalStateException("Cannot normalize target loads from zero displacement");
        }
        double[][] targets = new double[TARGET_MM.length][];
        double[] targetPressures = new double[TARGET_MM.length];
        for (int i = 0; i < TARGET_MM.length; i++) {
            targetPressures[i] = PROBE_PRESSURE_PA * TARGET_MM[i] / referenceAbsW;
            targets[i] = solveFullTarget(model, targetPressures[i], TARGET_MM[i]);
        }
        double[] full = targets[targets.length - 1];
        boolean solverHasProblems = model.sol("sol1").hasProblems();
        double[] weakMomentResiduals;
        String fieldResidualStatus = "pass";
        try {
            weakMomentResiduals = computeWeakMomentResiduals(
                model, full[P_PRESSURE_PA]
            );
        } catch (RuntimeException residualError) {
            weakMomentResiduals = new double[] {
                Double.NaN, Double.NaN, Double.NaN, Double.NaN
            };
            fieldResidualStatus = "fail_" + csvSafe(residualError.getMessage());
        }
        ModelUtil.showProgress((String) null);
        double[] solverConvergence;
        try {
            solverConvergence = parseFinalSolverConvergence(progressFile);
        } catch (RuntimeException convergenceError) {
            solverConvergence = new double[2 * FIELD_GROUP_COUNT];
            for (int i = 0; i < solverConvergence.length; i++) {
                solverConvergence[i] = Double.NaN;
            }
            fieldResidualStatus = "fail_" + csvSafe(convergenceError.getMessage());
        }
        double globalLinearResidual = maximum(
            solverConvergence, CONVERGENCE_LINEAR_RESIDUAL_START, FIELD_GROUP_COUNT
        );
        boolean residualPass = true;
        for (double residual : weakMomentResiduals) {
            residualPass = residualPass && finite(residual)
                && residual <= PHYSICS_WEAK_MOMENT_LIMIT;
        }
        for (double convergenceMetric : solverConvergence) {
            residualPass = residualPass && finite(convergenceMetric)
                && convergenceMetric <= SOLVER_CONVERGENCE_LIMIT;
        }
        boolean fieldsPass = true;
        for (double[] target : targets) {
            fieldsPass = fieldsPass && finite(target[P_W_MM]) && Math.abs(target[P_W_MM]) > 0.0
                && finite(target[P_PHI_SPAN_V]) && finite(target[P_PSI_SPAN_A])
                && finite(target[P_T_AVG_K]);
        }
        boolean completed = "pass".equals(isolationStatus)
            && !solverHasProblems && residualPass && fieldsPass;

        String status = completed
            ? "completed_full_field"
            : "blocked_full_field_validation";
        String tier = completed ? EVIDENCE_TIER : "blocked_not_A";
        writeLayerCsv(full);
        writeSummaryCsv(targets, targetPressures, status, tier);
        writePhysicsManifest(
            weakMomentResiduals, solverConvergence, fieldResidualStatus,
            globalLinearResidual,
            isolationStatus, solverHasProblems, status, tier
        );
        writeChannelIsolationCsv(electricOnly, magneticOnly, thermalOnly, isolationStatus);

        System.out.println("FOUR_FIELD_RESULT,status," + status
            + ",isolation," + isolationStatus
            + ",global_LinRes," + globalLinearResidual
            + ",mechanical_force_balance_residual," + weakMomentResiduals[0]
            + ",electric_weak_moment_residual," + weakMomentResiduals[1]
            + ",magnetic_weak_moment_residual," + weakMomentResiduals[2]
            + ",thermal_weak_moment_residual," + weakMomentResiduals[3]
            + ",electric_discrete_group_error,"
                + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_ELECTRIC]
            + ",magnetic_discrete_group_error,"
                + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_MAGNETIC]
            + ",thermal_discrete_group_error,"
                + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_THERMAL]
            + ",solver_has_problems," + solverHasProblems
            + ",w_center_mm," + full[P_W_MM]
            + ",phi_span_V," + full[P_PHI_SPAN_V]
            + ",psi_span_A," + full[P_PSI_SPAN_A]
            + ",T_average_K," + full[P_T_AVG_K]);

        File modelPath = new File(outputDirectory, "comsol_four_field_Model.mph");
        try {
            model.save(modelPath.getAbsolutePath());
        } catch (IOException ex) {
            throw new RuntimeException("Cannot save four-field COMSOL model: " + modelPath, ex);
        }
        if (!completed) {
            throw new IllegalStateException(
                "Four-field solve did not meet the evidence gate; inspect "
                + new File(outputDirectory, "comsol_four_field_physics_manifest.csv")
            );
        }
        return model;
    }

    private static void configureParameters(Model model) {
        double c11 = YOUNG / (1.0 - NU * NU);
        double c12 = YOUNG * NU / (1.0 - NU * NU);
        double e31 = D31 * c11 + D32 * c12;
        double e32 = D31 * c12 + D32 * c11;
        double gEffective = G33 - D31 * e31 - D32 * e32;

        model.param().set("pLoad", number(PROBE_PRESSURE_PA) + "[Pa]");
        model.param().set("gateE", "1");
        model.param().set("gateM", "1");
        model.param().set("gateT", "1");
        model.param().set("e31c", number(e31));
        model.param().set("e32c", number(e32));
        model.param().set("q31c", number(Q31));
        model.param().set("q32c", number(Q32));
        model.param().set("g33c", number(gEffective));
        model.param().set("k33c", number(K33));
        model.param().set("r33c", number(R33));
        model.param().set("beta1c", number(BETA1));
        model.param().set("beta2c", number(BETA2));
        model.param().set("pyroEc", number(PYRO_E));
        model.param().set("pyroMc", number(PYRO_M));
        model.param().set("heatCapc", number(HEAT_CAPACITY));
        model.param().set("phiScale", number(PHI_SCALE));
        model.param().set("psiScale", number(PSI_SCALE));
        model.param().set("tempScale", number(TEMP_SCALE));
        model.param().set("dScale", number(ELECTRIC_FLUX_SCALE));
        model.param().set("bScale", number(MAGNETIC_FLUX_SCALE));
    }

    private static void createGeometryAndSelections(Model model) {
        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").lengthUnit("m");
        for (int i = 0; i < PHYSICAL_LAYER_COUNT; i++) {
            String tag = "blk" + (i + 1);
            double z0 = -H / 2.0 + i * LAYER_THICKNESS;
            model.component("comp1").geom("geom1").create(tag, "Block");
            model.component("comp1").geom("geom1").feature(tag).set("base", "corner");
            model.component("comp1").geom("geom1").feature(tag).set(
                "size", new String[] {number(L), number(W), number(LAYER_THICKNESS)}
            );
            model.component("comp1").geom("geom1").feature(tag).set(
                "pos", new String[] {"0", "0", number(z0)}
            );
        }
        model.component("comp1").geom("geom1").run();

        createBoxSelection(model, "sel_fixed", 2,
            "-1e-9", "1e-9", "-1e-9", "0.300000001", "-0.003000001", "0.003000001");
        createBoxSelection(model, "sel_top", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "0.002999999", "0.003000001");
        createBoxSelection(model, "sel_bottom", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        createBoxSelection(model, "sel_bottom_edges", 1,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        createBoxSelection(model, "sel_all_domains", 3,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "0.003000001");
        createBoxSelection(model, "sel_all_boundaries", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "0.003000001");
        for (int i = 0; i < PHYSICAL_LAYER_COUNT; i++) {
            double z0 = -H / 2.0 + i * LAYER_THICKNESS;
            double z1 = z0 + LAYER_THICKNESS;
            createBoxSelection(model, "sel_layer_" + (i + 1), 3,
                "-1e-9", "0.300000001", "-1e-9", "0.300000001",
                number(z0 - 1e-9), number(z1 + 1e-9));
            createBoxSelection(model, "sel_gauge_" + (i + 1), 0,
                "-1e-9", "1e-9", "-1e-9", "1e-9",
                number(z0 - 1e-9), number(z0 + 1e-9));
        }
        for (int i = 0; i <= PHYSICAL_LAYER_COUNT; i++) {
            double z = -H / 2.0 + i * LAYER_THICKNESS;
            createBoxSelection(model, "sel_interface_" + i, 2,
                "-1e-9", "0.300000001", "-1e-9", "0.300000001",
                number(z - 1e-9), number(z + 1e-9));
        }

        int fixedCount = model.component("comp1").selection("sel_fixed").entities(2).length;
        int topCount = model.component("comp1").selection("sel_top").entities(2).length;
        int bottomCount = model.component("comp1").selection("sel_bottom").entities(2).length;
        int domainCount = model.component("comp1").selection("sel_all_domains").entities(3).length;
        if (fixedCount != PHYSICAL_LAYER_COUNT || topCount != 1 || bottomCount != 1
                || domainCount != PHYSICAL_LAYER_COUNT) {
            throw new IllegalStateException("Unsafe selection counts: fixed=" + fixedCount
                + ",top=" + topCount + ",bottom=" + bottomCount
                + ",domains=" + domainCount);
        }
        for (int i = 0; i < PHYSICAL_LAYER_COUNT; i++) {
            int count = model.component("comp1").selection("sel_layer_" + (i + 1))
                .entities(3).length;
            if (count != 1) {
                throw new IllegalStateException("Physical layer " + (i + 1)
                    + " selection has " + count + " domains; expected one");
            }
            int gaugeCount = model.component("comp1").selection("sel_gauge_" + (i + 1))
                .entities(0).length;
            if (gaugeCount != 1) {
                throw new IllegalStateException("Physical layer " + (i + 1)
                    + " gauge selection has " + gaugeCount + " points; expected one");
            }
        }
        for (int i = 0; i <= PHYSICAL_LAYER_COUNT; i++) {
            int count = model.component("comp1").selection("sel_interface_" + i)
                .entities(2).length;
            if (count != 1) {
                throw new IllegalStateException("Layer interface " + i
                    + " selection has " + count + " boundaries; expected one");
            }
        }
    }

    private static void createMaterial(Model model) {
        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("U Vf0.6 ten-layer four-field material");
        model.component("comp1").material("mat1").selection().all();
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("youngsmodulus", number(YOUNG) + "[Pa]");
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("poissonsratio", number(NU));
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("density", number(RHO) + "[kg/m^3]");
    }

    private static void createSolidMechanics(Model model) {
        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").prop("ShapeProperty")
            .set("order_displacement", "2s");
        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1")
            .selection().named("sel_fixed");
        model.component("comp1").physics("solid").create("load1", "BoundaryLoad", 2);
        model.component("comp1").physics("solid").feature("load1")
            .selection().named("sel_top");
        model.component("comp1").physics("solid").feature("load1")
            .set("LoadType", "ForceArea");
        model.component("comp1").physics("solid").feature("load1")
            .set("FperArea", new String[] {"0", "0", "-pLoad"});

        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String tag = "fourFieldStress" + i;
            model.component("comp1").physics("solid").feature("lemm1")
                .create(tag, "ExternalStress", 3);
            model.component("comp1").physics("solid").feature("lemm1")
                .feature(tag).selection().named("sel_layer_" + i);
            model.component("comp1").physics("solid").feature("lemm1")
                .feature(tag).set("StressInputType", "StressTensorMaterial");
            model.component("comp1").physics("solid").feature("lemm1")
                .feature(tag).set("ContributionType", "Stress");
            model.component("comp1").physics("solid").feature("lemm1")
                .feature(tag).set("Sext", new String[] {
                    "sigmaCoupledX" + i + "*1[Pa]", "0", "0",
                    "0", "sigmaCoupledY" + i + "*1[Pa]", "0",
                    "0", "0", "0"
                });
        }
    }

    private static void createElectricWeakForm(Model model) {
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String physicsTag = "we" + i;
            String field = "phiN" + i;
            model.component("comp1").physics().create(
                physicsTag, "WeakFormPDE", "geom1", new String[] {field}
            );
            model.component("comp1").physics(physicsTag)
                .selection().named("sel_layer_" + i);
            model.component("comp1").physics(physicsTag).feature("wfeq1").set(
                "weak", new String[] {
                    "-(test(" + field + "x)*DnX" + i
                        + "+test(" + field + "y)*DnY" + i
                        + "+test(" + field + "z)*DnZ" + i + ")"
                }
            );
            model.component("comp1").physics(physicsTag).create(
                "gaugeE" + i, "PointwiseConstraint", 0
            );
            model.component("comp1").physics(physicsTag).feature("gaugeE" + i)
                .selection().named("sel_gauge_" + i);
            model.component("comp1").physics(physicsTag).feature("gaugeE" + i)
                .set("constraintExpression", new String[] {field});
        }
    }

    private static void createMagneticWeakForm(Model model) {
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String physicsTag = "wm" + i;
            String field = "psiN" + i;
            model.component("comp1").physics().create(
                physicsTag, "WeakFormPDE", "geom1", new String[] {field}
            );
            model.component("comp1").physics(physicsTag)
                .selection().named("sel_layer_" + i);
            model.component("comp1").physics(physicsTag).feature("wfeq1").set(
                "weak", new String[] {
                    "-(test(" + field + "x)*BnX" + i
                        + "+test(" + field + "y)*BnY" + i
                        + "+test(" + field + "z)*BnZ" + i + ")"
                }
            );
            model.component("comp1").physics(physicsTag).create(
                "gaugeM" + i, "PointwiseConstraint", 0
            );
            model.component("comp1").physics(physicsTag).feature("gaugeM" + i)
                .selection().named("sel_gauge_" + i);
            model.component("comp1").physics(physicsTag).feature("gaugeM" + i)
                .set("constraintExpression", new String[] {field});
        }
    }

    private static void createThermalWeakForm(Model model) {
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String physicsTag = "wt" + i;
            String field = "tempN" + i;
            model.component("comp1").physics().create(
                physicsTag, "WeakFormPDE", "geom1", new String[] {field}
            );
            model.component("comp1").physics(physicsTag)
                .selection().named("sel_layer_" + i);
            model.component("comp1").physics(physicsTag).feature("wfeq1").set(
                "weak", new String[] {
                    "-test(" + field + ")*thermalClosure" + i
                }
            );
        }
    }

    private static void createCoupledVariables(Model model) {
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String tag = "fourFieldVars" + i;
            String phi = "phiN" + i;
            String psi = "psiN" + i;
            String temp = "tempN" + i;
            model.component("comp1").variable().create(tag);
            model.component("comp1").variable(tag)
                .selection().named("sel_layer_" + i);
            model.component("comp1").variable(tag).set(
                "phi_field" + i, "phiScale*" + phi
            );
            model.component("comp1").variable(tag).set(
                "psi_field" + i, "psiScale*" + psi
            );
            model.component("comp1").variable(tag).set(
                "T_field" + i, "tempScale*" + temp
            );
            model.component("comp1").variable(tag).set(
                "DnX" + i, "(-g33c*phiScale*" + phi + "x"
                    + "-gateE*gateM*k33c*psiScale*" + psi + "x)/dScale"
            );
            model.component("comp1").variable(tag).set(
                "DnY" + i, "(-g33c*phiScale*" + phi + "y"
                    + "-gateE*gateM*k33c*psiScale*" + psi + "y)/dScale"
            );
            model.component("comp1").variable(tag).set(
                "DnZ" + i, "(gateE*(e31c*solid.eXX+e32c*solid.eYY)"
                    + "-g33c*phiScale*" + phi + "z"
                    + "-gateE*gateM*k33c*psiScale*" + psi + "z"
                    + "+gateE*gateT*pyroEc*tempScale*" + temp + ")/dScale"
            );
            model.component("comp1").variable(tag).set(
                "BnX" + i, "(-r33c*psiScale*" + psi + "x"
                    + "-gateE*gateM*k33c*phiScale*" + phi + "x)/bScale"
            );
            model.component("comp1").variable(tag).set(
                "BnY" + i, "(-r33c*psiScale*" + psi + "y"
                    + "-gateE*gateM*k33c*phiScale*" + phi + "y)/bScale"
            );
            model.component("comp1").variable(tag).set(
                "BnZ" + i, "(gateM*(q31c*solid.eXX+q32c*solid.eYY)"
                    + "-r33c*psiScale*" + psi + "z"
                    + "-gateE*gateM*k33c*phiScale*" + phi + "z"
                    + "+gateM*gateT*pyroMc*tempScale*" + temp + ")/bScale"
            );
            model.component("comp1").variable(tag).set(
                "thermalClosure" + i, temp
                    + "+gateT*(beta1c*solid.eXX+beta2c*solid.eYY)/heatCapc"
            );
            model.component("comp1").variable(tag).set(
                "sigmaCoupledX" + i, "-gateT*beta1c*tempScale*" + temp
            );
            model.component("comp1").variable(tag).set(
                "sigmaCoupledY" + i, "-gateT*beta2c*tempScale*" + temp
            );
        }
    }

    private static void createMesh(Model model) {
        int[] bottomFaces = model.component("comp1").selection("sel_bottom").entities(2);
        int[] bottomEdges = model.component("comp1").selection("sel_bottom_edges").entities(1);
        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").create("map1", "Map");
        model.component("comp1").mesh("mesh1").feature("map1").selection().set(bottomFaces);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .selection().set(bottomEdges);
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .set("numelem", INPLANE_DIVISIONS);
        model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
        model.component("comp1").mesh("mesh1").feature("swe1")
            .selection("sourceface").set(bottomFaces);
        model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
        model.component("comp1").mesh("mesh1").feature("swe1").set("sweeppath", "straight");
        model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1")
            .set("numelem", PHYSICAL_LAYER_COUNT * THICKNESS_DIVISIONS_PER_LAYER);
        model.component("comp1").mesh("mesh1").run();
        long elements = model.component("comp1").mesh("mesh1").getNumElem();
        if (elements <= 0) {
            throw new IllegalStateException("Four-field mesh contains no elements");
        }
        System.out.println("FOUR_FIELD_MESH,elements," + elements
            + ",inplane_divisions," + INPLANE_DIVISIONS
            + ",thickness_divisions_per_layer," + THICKNESS_DIVISIONS_PER_LAYER);
    }

    private static void createStationaryStudy(Model model) {
        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            model.study("std1").feature("stat").setSolveFor("/physics/we" + i, true);
            model.study("std1").feature("stat").setSolveFor("/physics/wm" + i, true);
            model.study("std1").feature("stat").setSolveFor("/physics/wt" + i, true);
        }

        model.sol().create("sol1");
        model.sol("sol1").study("std1");
        model.sol("sol1").createAutoSequence("std1");
        boolean stationaryFeatureFound = false;
        StringBuilder solverTags = new StringBuilder();
        for (String tag : model.sol("sol1").feature().tags()) {
            if (solverTags.length() > 0) {
                solverTags.append('|');
            }
            solverTags.append(tag);
            if ("s1".equals(tag)) {
                stationaryFeatureFound = true;
            }
        }
        if (!stationaryFeatureFound) {
            throw new IllegalStateException(
                "Auto solver sequence has no stationary feature s1; tags=" + solverTags
            );
        }
        model.sol("sol1").attach("std1");
        model.sol("sol1").feature("s1").set("control", "user");
        model.sol("sol1").feature("s1").set(
            "stol", STATIONARY_RELATIVE_TOLERANCE
        );
        boolean segregatedFeatureFound = false;
        StringBuilder stationaryChildTags = new StringBuilder();
        StringBuilder segregatedStepTags = new StringBuilder();
        for (String tag : model.sol("sol1").feature("s1").feature().tags()) {
            if (stationaryChildTags.length() > 0) {
                stationaryChildTags.append('|');
            }
            stationaryChildTags.append(tag);
            if (!tag.startsWith("se")) {
                continue;
            }
            segregatedFeatureFound = true;
            model.sol("sol1").feature("s1").feature(tag)
                .set("segterm", "iter");
            model.sol("sol1").feature("s1").feature(tag)
                .set("segiter", SEGREGATED_FIXED_ITERATIONS);
            for (String stepTag : model.sol("sol1").feature("s1")
                    .feature(tag).feature().tags()) {
                if (!stepTag.startsWith("ss")) {
                    continue;
                }
                if (segregatedStepTags.length() > 0) {
                    segregatedStepTags.append('|');
                }
                segregatedStepTags.append(stepTag);
            }
        }
        if (!segregatedFeatureFound) {
            throw new IllegalStateException(
                "Auto solver sequence has no segregated feature; stationary children="
                    + stationaryChildTags
            );
        }
        System.out.println("FOUR_FIELD_SOLVER_SETUP,stationary_feature,s1,stol,"
            + STATIONARY_RELATIVE_TOLERANCE + ",top_level_tags," + solverTags
            + ",stationary_child_tags," + stationaryChildTags
            + ",segregated_step_tags," + segregatedStepTags
            + ",segregated_fixed_iterations," + SEGREGATED_FIXED_ITERATIONS
            + ",residual_termination,fixed_iterations_with_final_gate"
            + ",direct_error_check,comsol_default");
    }

    private static void validateApiSmoke(Model model) {
        requirePhysics(model, "solid");
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            requirePhysics(model, "we" + i);
            requirePhysics(model, "wm" + i);
            requirePhysics(model, "wt" + i);
            if (model.component("comp1").physics("solid").feature("lemm1")
                    .feature("fourFieldStress" + i) == null
                    || model.component("comp1").physics("we" + i)
                        .feature("gaugeE" + i) == null
                    || model.component("comp1").physics("wm" + i)
                        .feature("gaugeM" + i) == null) {
                throw new IllegalStateException(
                    "Four-field API smoke failed in physical layer " + i
                );
            }
        }
        System.out.println("FOUR_FIELD_API_SMOKE,status,pass,physics,solid|10we|10wm|10wt");
    }

    private static void requirePhysics(Model model, String tag) {
        boolean found = false;
        for (String actual : model.component("comp1").physics().tags()) {
            if (tag.equals(actual)) {
                found = true;
                break;
            }
        }
        if (!found) {
            throw new IllegalStateException("Four-field API smoke missing physics: " + tag);
        }
    }

    private static double[] solveChannel(Model model, double gateE, double gateM,
            double gateT, String name) {
        model.param().set("gateE", number(gateE));
        model.param().set("gateM", number(gateM));
        model.param().set("gateT", number(gateT));
        model.sol("sol1").runAll();
        if (model.sol("sol1").hasProblems()) {
            throw new IllegalStateException("COMSOL channel solve has problems: " + name);
        }
        double[] result = probe(model);
        System.out.println("FOUR_FIELD_CHANNEL,name," + name
            + ",w_mm," + result[P_W_MM]
            + ",phi_span_V," + result[P_PHI_SPAN_V]
            + ",psi_span_A," + result[P_PSI_SPAN_A]
            + ",T_avg_K," + result[P_T_AVG_K]);
        return result;
    }

    private static double[] solveFullTarget(Model model, double pressurePa, double targetMm) {
        model.param().set("gateE", "1");
        model.param().set("gateM", "1");
        model.param().set("gateT", "1");
        model.param().set("pLoad", number(pressurePa) + "[Pa]");
        model.sol("sol1").runAll();
        if (model.sol("sol1").hasProblems()) {
            throw new IllegalStateException("COMSOL target solve has problems: " + targetMm + " mm");
        }
        double[] result = probe(model);
        result[P_PRESSURE_PA] = pressurePa;
        double displacementError = Math.abs(Math.abs(result[P_W_MM]) - targetMm) / targetMm;
        if (!finite(displacementError) || displacementError > 1.0e-3) {
            throw new IllegalStateException("COMSOL target displacement mismatch at " + targetMm
                + " mm: solved=" + result[P_W_MM] + ", relative_error=" + displacementError);
        }
        System.out.println("FOUR_FIELD_TARGET,target_mm," + targetMm
            + ",pressure_Pa," + pressurePa + ",direct_w_mm," + result[P_W_MM]
            + ",phi_span_V," + result[P_PHI_SPAN_V]
            + ",psi_span_A," + result[P_PSI_SPAN_A]);
        return result;
    }

    private static double[] probe(Model model) {
        double[] p = new double[PROBE_SIZE];
        p[P_W_MM] = 1000.0 * interpolateScalar(model, "w", 0.15, 0.15, 0.0);
        p[P_EX_AVG] = volumeAverage(model, "solid.eXX");
        p[P_EY_AVG] = volumeAverage(model, "solid.eYY");
        p[P_PRESSURE_PA] = Double.NaN;
        double phiMin = Double.POSITIVE_INFINITY;
        double phiMax = Double.NEGATIVE_INFINITY;
        double psiMin = Double.POSITIVE_INFINITY;
        double psiMax = Double.NEGATIVE_INFINITY;
        double temperatureSum = 0.0;
        for (int i = 0; i < PHYSICAL_LAYER_COUNT; i++) {
            int layer = i + 1;
            String selection = "sel_layer_" + (i + 1);
            p[layerIndex(i, P_LAYER_EX)] = volumeAverage(model, "solid.eXX", selection);
            p[layerIndex(i, P_LAYER_EY)] = volumeAverage(model, "solid.eYY", selection);
            p[layerIndex(i, P_LAYER_T)] = volumeAverage(
                model, "T_field" + layer, selection
            );
            p[layerIndex(i, P_LAYER_PHI)] = LAYER_THICKNESS * volumeAverage(
                model, "phiScale*phiN" + layer + "z", selection
            );
            p[layerIndex(i, P_LAYER_PSI)] = LAYER_THICKNESS * volumeAverage(
                model, "psiScale*psiN" + layer + "z", selection
            );
            phiMin = Math.min(phiMin, p[layerIndex(i, P_LAYER_PHI)]);
            phiMax = Math.max(phiMax, p[layerIndex(i, P_LAYER_PHI)]);
            psiMin = Math.min(psiMin, p[layerIndex(i, P_LAYER_PSI)]);
            psiMax = Math.max(psiMax, p[layerIndex(i, P_LAYER_PSI)]);
            temperatureSum += p[layerIndex(i, P_LAYER_T)];
        }
        p[P_PHI_BOTTOM_V] = phiMin;
        p[P_PHI_TOP_V] = phiMax;
        p[P_PSI_BOTTOM_A] = psiMin;
        p[P_PSI_TOP_A] = psiMax;
        p[P_PHI_SPAN_V] = phiMax - phiMin;
        p[P_PSI_SPAN_A] = psiMax - psiMin;
        p[P_T_AVG_K] = temperatureSum / PHYSICAL_LAYER_COUNT;
        return p;
    }

    private static int layerIndex(int layerZeroBased, int offset) {
        return P_LAYER_START + layerZeroBased * P_LAYER_STRIDE + offset;
    }

    private static boolean validateChannelIsolation(double[] electric, double[] magnetic,
            double[] thermal) {
        boolean electricPass = electric[P_PHI_SPAN_V] > 1e-10
            && nearZero(electric[P_PSI_SPAN_A]) && nearZero(electric[P_T_AVG_K]);
        boolean magneticPass = magnetic[P_PSI_SPAN_A] > 1e-10
            && nearZero(magnetic[P_PHI_SPAN_V]) && nearZero(magnetic[P_T_AVG_K]);
        boolean thermalPass = Math.abs(thermal[P_T_AVG_K]) > 1e-10
            && nearZero(thermal[P_PHI_SPAN_V]) && nearZero(thermal[P_PSI_SPAN_A]);
        return electricPass && magneticPass && thermalPass;
    }

    private static boolean nearZero(double value) {
        return finite(value) && Math.abs(value) <= 1e-8;
    }

    private static double[] computeWeakMomentResiduals(Model model, double pressurePa) {
        double appliedForce = pressurePa * L * W;
        double reactionForce = surfaceIntegral(model, "solid.RFz", "sel_fixed");
        double mechanical = Math.abs(Math.abs(reactionForce) - appliedForce)
            / Math.max(appliedForce, 1e-30);

        double electric = 0.0;
        double magnetic = 0.0;
        double thermal = 0.0;
        for (int i = 1; i <= PHYSICAL_LAYER_COUNT; i++) {
            String selection = "sel_layer_" + i;
            double electricNumerator = Math.abs(volumeAverage(
                model, "DnZ" + i, selection
            ));
            double electricDenominator = volumeAverage(model,
                "(abs(gateE*(e31c*solid.eXX+e32c*solid.eYY))"
                    + "+abs(g33c*phiScale*phiN" + i + "z)"
                    + "+abs(gateE*gateM*k33c*psiScale*psiN" + i + "z)"
                    + "+abs(gateE*gateT*pyroEc*tempScale*tempN" + i + "))/dScale",
                selection
            );
            electric = Math.max(electric,
                electricNumerator / Math.max(electricDenominator, 1e-30));

            double magneticNumerator = Math.abs(volumeAverage(
                model, "BnZ" + i, selection
            ));
            double magneticDenominator = volumeAverage(model,
                "(abs(gateM*(q31c*solid.eXX+q32c*solid.eYY))"
                    + "+abs(r33c*psiScale*psiN" + i + "z)"
                    + "+abs(gateE*gateM*k33c*phiScale*phiN" + i + "z)"
                    + "+abs(gateM*gateT*pyroMc*tempScale*tempN" + i + "))/bScale",
                selection
            );
            magnetic = Math.max(magnetic,
                magneticNumerator / Math.max(magneticDenominator, 1e-30));

            double thermalNumerator = Math.abs(volumeAverage(
                model, "thermalClosure" + i, selection
            ));
            double thermalDenominator = volumeAverage(model,
                "abs(tempN" + i + ")"
                    + "+abs(gateT*(beta1c*solid.eXX+beta2c*solid.eYY)/heatCapc)",
                selection
            );
            thermal = Math.max(thermal,
                thermalNumerator / Math.max(thermalDenominator, 1e-30));
        }
        return new double[] {mechanical, electric, magnetic, thermal};
    }

    /**
     * Parse two distinct convergence quantities from the final completed
     * segregated outer iteration.  The group error estimates are the outer
     * nonlinear/segregated convergence metric.  LinRes is retained separately
     * as the inner linear-solver residual; it is not relabelled as a physical
     * conservation residual.
     */
    private static double[] parseFinalSolverConvergence(File progressFile) {
        double[] linearResidualRing = new double[FINAL_SOLVER_GROUP_COUNT];
        for (int i = 0; i < linearResidualRing.length; i++) {
            linearResidualRing[i] = Double.NaN;
        }
        double[] finalGroupErrors = null;
        int linearResidualCount = 0;
        int groupVectorCount = 0;
        boolean linearHeaderSeen = false;
        boolean expectGroupErrorVector = false;
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new FileReader(progressFile));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.contains("Segregated group error estimate")
                        || line.contains("分离组误差估计")) {
                    expectGroupErrorVector = true;
                    continue;
                }
                double[] vector = parseCommaVector(line, FINAL_SOLVER_GROUP_COUNT);
                if (vector != null) {
                    // The localized label is preferred.  Pair parity is a
                    // fallback for installations whose progress-log encoding
                    // prevents matching the Chinese label: each COMSOL outer
                    // iteration writes error-estimate then residual-estimate.
                    if (expectGroupErrorVector || groupVectorCount % 2 == 0) {
                        finalGroupErrors = vector;
                    }
                    groupVectorCount++;
                    expectGroupErrorVector = false;
                    continue;
                }
                if (line.contains("LinRes")) {
                    linearHeaderSeen = true;
                    continue;
                }
                if (!linearHeaderSeen) {
                    continue;
                }
                String trimmed = line.trim();
                if (!trimmed.matches("^[0-9]+\\s+.*")) {
                    continue;
                }
                String[] parts = trimmed.split("\\s+");
                if (parts.length < 8) {
                    continue;
                }
                try {
                    linearResidualRing[
                        linearResidualCount % linearResidualRing.length
                    ] = Double.parseDouble(parts[parts.length - 1]);
                    linearResidualCount++;
                } catch (NumberFormatException ignored) {
                    // A progress line can begin with a digit; keep scanning.
                }
            }
        } catch (IOException ex) {
            throw new RuntimeException("Cannot read COMSOL progress log: " + progressFile, ex);
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException ignored) {
                    // Nothing useful can be done during cleanup.
                }
            }
        }
        if (finalGroupErrors == null) {
            throw new IllegalStateException(
                "No complete segregated group error vector in COMSOL progress log"
            );
        }
        if (linearResidualCount < linearResidualRing.length) {
            throw new IllegalStateException(
                "Fewer than " + FINAL_SOLVER_GROUP_COUNT
                    + " final linear residuals in COMSOL progress log"
            );
        }
        double[] finalLinearResiduals = new double[FINAL_SOLVER_GROUP_COUNT];
        int start = linearResidualCount % linearResidualRing.length;
        for (int i = 0; i < finalLinearResiduals.length; i++) {
            finalLinearResiduals[i] = linearResidualRing[
                (start + i) % linearResidualRing.length
            ];
            if (!finite(finalLinearResiduals[i]) || !finite(finalGroupErrors[i])) {
                throw new IllegalStateException(
                    "Non-finite final COMSOL convergence metric at group " + i
                );
            }
        }

        double[] convergence = new double[2 * FIELD_GROUP_COUNT];
        convergence[CONVERGENCE_GROUP_ERROR_START + GROUP_SOLID]
            = Math.abs(finalGroupErrors[0]);
        convergence[CONVERGENCE_GROUP_ERROR_START + GROUP_ELECTRIC]
            = maximum(finalGroupErrors, 1, PHYSICAL_LAYER_COUNT);
        convergence[CONVERGENCE_GROUP_ERROR_START + GROUP_MAGNETIC]
            = maximum(finalGroupErrors, 1 + PHYSICAL_LAYER_COUNT, PHYSICAL_LAYER_COUNT);
        convergence[CONVERGENCE_GROUP_ERROR_START + GROUP_THERMAL]
            = maximum(finalGroupErrors, 1 + 2 * PHYSICAL_LAYER_COUNT, PHYSICAL_LAYER_COUNT);
        convergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_SOLID]
            = Math.abs(finalLinearResiduals[0]);
        convergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_ELECTRIC]
            = maximum(finalLinearResiduals, 1, PHYSICAL_LAYER_COUNT);
        convergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_MAGNETIC]
            = maximum(finalLinearResiduals, 1 + PHYSICAL_LAYER_COUNT, PHYSICAL_LAYER_COUNT);
        convergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_THERMAL]
            = maximum(finalLinearResiduals, 1 + 2 * PHYSICAL_LAYER_COUNT, PHYSICAL_LAYER_COUNT);
        return convergence;
    }

    private static double[] parseCommaVector(String line, int expectedLength) {
        String trimmed = line.trim();
        if (trimmed.indexOf(',') < 0) {
            return null;
        }
        String[] parts = trimmed.split(",");
        if (parts.length != expectedLength) {
            return null;
        }
        double[] values = new double[expectedLength];
        for (int i = 0; i < parts.length; i++) {
            try {
                values[i] = Double.parseDouble(parts[i].trim());
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return values;
    }

    private static double maximum(double[] values, int start, int count) {
        double maximum = 0.0;
        for (int i = start; i < start + count; i++) {
            if (!finite(values[i])) {
                return Double.NaN;
            }
            maximum = Math.max(maximum, Math.abs(values[i]));
        }
        return maximum;
    }

    private static void writeSummaryCsv(double[][] targets, double[] pressures,
            String status, String tier) {
        File path = new File(OUTPUT_DIR, "comsol_four_field_summary.csv");
        PrintWriter writer = writer(path);
        try {
            writer.println("case_id,mesh_divisions,thickness_divisions_per_layer,physical_layer_count,target_w_mm,"
                + "probe_pressure_Pa,probe_w_mm,comsol_electric_V,comsol_magnetic_A,"
                + "comsol_reciprocal_temperature_K,target_w_relative_error,target_solution_mode,status,evidence_tier,"
                + "run_id,source_sha256");
            for (int i = 0; i < TARGET_MM.length; i++) {
                double[] p = targets[i];
                double target = TARGET_MM[i];
                writer.println("inverse_CFFF_U_Vf06_10layer," + INPLANE_DIVISIONS
                    + "," + THICKNESS_DIVISIONS_PER_LAYER + "," + PHYSICAL_LAYER_COUNT
                    + "," + target + "," + pressures[i]
                    + "," + p[P_W_MM] + "," + Math.abs(p[P_PHI_SPAN_V])
                    + "," + Math.abs(p[P_PSI_SPAN_A])
                    + "," + p[P_T_AVG_K]
                    + "," + (Math.abs(Math.abs(p[P_W_MM]) - target) / target)
                    + ",independent_stationary_resolve," + status + "," + tier
                    + "," + RUN_ID + "," + SOURCE_SHA256);
            }
        } finally {
            writer.close();
        }
    }

    private static void writeLayerCsv(double[] p) {
        File path = new File(OUTPUT_DIR, "comsol_four_field_layers.csv");
        PrintWriter writer = writer(path);
        try {
            writer.println("layer,z_bottom_m,z_top_m,target_pressure_Pa,target_w_mm,"
                + "avg_eXX,avg_eYY,layer_delta_phi_V,layer_delta_psi_A,"
                + "reciprocal_temperature_avg_K,run_id,source_sha256");
            for (int i = 0; i < PHYSICAL_LAYER_COUNT; i++) {
                double z0 = -H / 2.0 + i * LAYER_THICKNESS;
                double z1 = z0 + LAYER_THICKNESS;
                writer.println((i + 1) + "," + z0 + "," + z1 + "," + p[P_PRESSURE_PA]
                    + "," + p[P_W_MM] + "," + p[layerIndex(i, P_LAYER_EX)]
                    + "," + p[layerIndex(i, P_LAYER_EY)]
                    + "," + p[layerIndex(i, P_LAYER_PHI)]
                    + "," + p[layerIndex(i, P_LAYER_PSI)]
                    + "," + p[layerIndex(i, P_LAYER_T)]
                    + "," + RUN_ID + "," + SOURCE_SHA256);
            }
        } finally {
            writer.close();
        }
    }

    private static void writePhysicsManifest(double[] weakMomentResiduals,
            double[] solverConvergence, String residualEvaluationStatus,
            double solverResidual, String isolationStatus, boolean solverHasProblems,
            String status, String tier) {
        File path = new File(OUTPUT_DIR, "comsol_four_field_physics_manifest.csv");
        PrintWriter writer = writer(path);
        try {
            writer.println("case_id,solve_u,solve_phi,solve_psi,solve_T,method,evidence_tier,"
                + "mechanical_force_balance_residual,electric_weak_moment_residual,"
                + "magnetic_weak_moment_residual,thermal_weak_moment_residual,"
                + "solid_discrete_segregated_group_relative_error,"
                + "electric_discrete_segregated_group_relative_error,"
                + "magnetic_discrete_segregated_group_relative_error,"
                + "thermal_discrete_segregated_group_relative_error,"
                + "solid_solver_linear_residual,electric_solver_linear_residual,"
                + "magnetic_solver_linear_residual,thermal_solver_linear_residual,"
                + "status,same_stationary,open_circuit_electric,"
                + "open_circuit_magnetic,insulated_thermal,independent_dof_fields,"
                + "api_channel_isolation_status,solver_has_problems,residual_definition,"
                + "solver_linear_residual,solver_relative_tolerance,"
                + "physics_residual_limit,solver_convergence_limit,mesh_divisions,"
                + "thickness_divisions_per_layer,"
                + "physical_layer_count,fg_mode,vf0,isomorphic_to_matlab_10layer,comparison_scope,"
                + "mechanical_discretization,geometry_material_boundary_layer_observable_aligned,"
                + "field_residual_evaluation_status,solver_strategy,coupling_equivalent_to_matlab,"
                + "convergence_termination,segregated_termination,"
                + "fixed_segregated_iterations,direct_error_check,"
                + "layer_field_layout,observable_definition,layer_drop_definition,run_id,source_sha256");
            writer.println("inverse_CFFF_U_Vf06_10layer,true,true,true,true," + METHOD
                + "," + tier + "," + weakMomentResiduals[0]
                + "," + weakMomentResiduals[1]
                + "," + weakMomentResiduals[2]
                + "," + weakMomentResiduals[3]
                + "," + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_SOLID]
                + "," + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_ELECTRIC]
                + "," + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_MAGNETIC]
                + "," + solverConvergence[CONVERGENCE_GROUP_ERROR_START + GROUP_THERMAL]
                + "," + solverConvergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_SOLID]
                + "," + solverConvergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_ELECTRIC]
                + "," + solverConvergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_MAGNETIC]
                + "," + solverConvergence[CONVERGENCE_LINEAR_RESIDUAL_START + GROUP_THERMAL]
                + "," + status
                + ",true,true,true,true,true," + isolationStatus + "," + solverHasProblems
                + ",mechanical=global_force_balance;weak_moment=max_layer_normalized_constitutive_flux_moment;discrete_group_error=max_final_outer_iteration_error_by_field;solver_linear_residual=max_final_inner_LinRes_by_field,"
                + solverResidual + "," + STATIONARY_RELATIVE_TOLERANCE
                + "," + PHYSICS_WEAK_MOMENT_LIMIT + "," + SOLVER_CONVERGENCE_LIMIT
                + "," + INPLANE_DIVISIONS + "," + THICKNESS_DIVISIONS_PER_LAYER
                + "," + PHYSICAL_LAYER_COUNT
                + ",U,0.6,false,same_geometry_material_boundary_observable_nonisomorphic_mechanics,"
                + "COMSOL_3D_quadratic_solid_vs_MATLAB_LRT5_shell,true,"
                + residualEvaluationStatus + ",segregated_same_stationary,true,"
                + "fixed_25_segregated_iterations_with_final_residual_gate,"
                + "iter,25,auto_enabled,"
                + "independent_per_physical_layer,"
                + "max_minus_min_of_layer_top_bottom_area_average_potential_difference,"
                + "layer_thickness_times_volume_average_potential_gradient_equivalent_to_face_average_difference,"
                + RUN_ID + "," + SOURCE_SHA256);
        } finally {
            writer.close();
        }
    }

    private static void writeChannelIsolationCsv(double[] electric, double[] magnetic,
            double[] thermal, String status) {
        File path = new File(OUTPUT_DIR, "comsol_four_field_channel_isolation.csv");
        PrintWriter writer = writer(path);
        try {
            writer.println("channel,gateE,gateM,gateT,w_center_mm,phi_span_V,psi_span_A,"
                + "reciprocal_temperature_avg_K,isolation_status");
            writeChannelRow(writer, "electric", 1, 0, 0, electric, status);
            writeChannelRow(writer, "magnetic", 0, 1, 0, magnetic, status);
            writeChannelRow(writer, "thermal", 0, 0, 1, thermal, status);
        } finally {
            writer.close();
        }
    }

    private static void writeChannelRow(PrintWriter writer, String channel,
            int gateE, int gateM, int gateT, double[] p, String status) {
        writer.println(channel + "," + gateE + "," + gateM + "," + gateT
            + "," + p[P_W_MM] + "," + p[P_PHI_SPAN_V] + "," + p[P_PSI_SPAN_A]
            + "," + p[P_T_AVG_K] + "," + status);
    }

    private static PrintWriter writer(File path) {
        try {
            return new PrintWriter(new FileWriter(path));
        } catch (IOException ex) {
            throw new RuntimeException("Cannot write COMSOL evidence file: " + path, ex);
        }
    }

    private static void clearStaleEvidence(File outputDirectory) {
        String[] names = new String[] {
            "comsol_four_field_summary.csv",
            "comsol_four_field_layers.csv",
            "comsol_four_field_physics_manifest.csv",
            "comsol_four_field_channel_isolation.csv",
            "comsol_four_field_java_error.log",
            "comsol_four_field_solver_progress.log"
        };
        for (String name : names) {
            File path = new File(outputDirectory, name);
            if (path.exists() && !path.delete()) {
                throw new IllegalStateException("Cannot remove stale four-field evidence: " + path);
            }
        }
    }

    private static double interpolateScalar(Model model, String expression,
            double x, double y, double z) {
        String tag = "interp" + (++numericalCounter);
        model.result().numerical().create(tag, "Interp");
        model.result().numerical(tag).set("expr", new String[] {expression});
        model.result().numerical(tag).set("coord", new double[][] {{x}, {y}, {z}});
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length >= 1 && values[0].length >= 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected interpolation result for " + expression);
    }

    private static double volumeAverage(Model model, String expression) {
        return volumeAverage(model, expression, "");
    }

    private static double volumeAverage(Model model, String expression, String selection) {
        String tag = "avg" + (++numericalCounter);
        model.result().numerical().create(tag, "AvVolume");
        if (selection == null || selection.length() == 0) {
            model.result().numerical(tag).selection().all();
        } else {
            model.result().numerical(tag).selection().named(selection);
        }
        model.result().numerical(tag).set("expr", new String[] {expression});
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length >= 1 && values[0].length >= 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected volume average result for " + expression);
    }

    private static double surfaceIntegral(Model model, String expression, String selection) {
        String tag = "surfInt" + (++numericalCounter);
        model.result().numerical().create(tag, "IntSurface");
        model.result().numerical(tag).selection().named(selection);
        model.result().numerical(tag).set("expr", new String[] {expression});
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length >= 1 && values[0].length >= 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected surface integral result for " + expression);
    }

    private static void createBoxSelection(Model model, String tag, int entityDim,
            String xmin, String xmax, String ymin, String ymax, String zmin, String zmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(entityDim));
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", xmin);
        model.component("comp1").selection(tag).set("xmax", xmax);
        model.component("comp1").selection(tag).set("ymin", ymin);
        model.component("comp1").selection(tag).set("ymax", ymax);
        model.component("comp1").selection(tag).set("zmin", zmin);
        model.component("comp1").selection(tag).set("zmax", zmax);
    }

    private static void validateConfiguration() {
        if (PROBE_PRESSURE_PA <= 0.0 || INPLANE_DIVISIONS < 1
                || THICKNESS_DIVISIONS_PER_LAYER < 1) {
            throw new IllegalArgumentException("Pressure and mesh divisions must be positive");
        }
        if ("missing_run_id".equals(RUN_ID) || "missing_source_sha256".equals(SOURCE_SHA256)) {
            throw new IllegalArgumentException(
                "FG_FOUR_FIELD_RUN_ID and FG_FOUR_FIELD_SOURCE_SHA256 are required"
            );
        }
    }

    private static boolean finite(double value) {
        return !Double.isNaN(value) && !Double.isInfinite(value);
    }

    private static String csvSafe(String value) {
        if (value == null || value.length() == 0) {
            return "unknown";
        }
        return value.replace(',', '_').replace('\n', '_').replace('\r', '_').replace(' ', '_');
    }

    private static String number(double value) {
        return String.format(Locale.US, "%.17g", value);
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.trim().length() == 0 ? defaultValue : value.trim();
    }

    private static int intEnv(String name, int defaultValue) {
        String value = env(name, "");
        return value.length() == 0 ? defaultValue : Integer.parseInt(value);
    }

    private static double doubleEnv(String name, double defaultValue) {
        String value = env(name, "");
        return value.length() == 0 ? defaultValue : Double.parseDouble(value);
    }

    public static void main(String[] args) {
        try {
            run();
        } catch (Throwable ex) {
            File directory = new File(OUTPUT_DIR);
            directory.mkdirs();
            PrintWriter errorWriter = writer(
                new File(directory, "comsol_four_field_java_error.log")
            );
            try {
                ex.printStackTrace(errorWriter);
            } finally {
                errorWriter.close();
            }
            if (ex instanceof RuntimeException) {
                throw (RuntimeException) ex;
            }
            throw new RuntimeException("Four-field COMSOL execution failed", ex);
        }
    }
}
