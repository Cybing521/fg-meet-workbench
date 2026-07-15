import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/**
 * Diagnostic COMSOL cross-check for displacement-to-electric/magnetic sensing.
 *
 * <p>A linear 3D solid CFFF plate is loaded by uniform top pressure.  The
 * pressure is calibrated from the solved centre displacement, and the layer
 * average in-plane strains are passed through exactly the same local
 * open-circuit MEE constitutive algebra used by the reduced MATLAB plate
 * formulation.  This is deliberately reported as a non-isomorphic Tier-B
 * cross-check: COMSOL supplies an independent 3D mechanical field, while the
 * sensor conversion remains a transparent constitutive postprocess.</p>
 */
public class RunInverseSensorCfffValidation {
    private static final double L = 0.300;
    private static final double W = 0.300;
    private static final double H = 0.006;
    private static final double HLAYER = 0.0006;
    private static final int NLAYER = 10;

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
    private static final double THERMO_COUPLING_1 = 2.356e6;
    private static final double THERMO_COUPLING_2 = 2.356e6;
    private static final double PYRO_E = 2.492e-4;
    private static final double PYRO_M = 5.900e-3;
    private static final double HEAT_CAPACITY = 4.252e2;

    private static final double PROBE_PRESSURE_PA = doubleEnv("FG_INVERSE_PROBE_PRESSURE_PA", 15000.0);
    private static final int INPLANE_DIVISIONS = intEnv("FG_INVERSE_INPLANE_DIVISIONS", 15);
    private static final int THROUGH_THICKNESS_DIVISIONS = intEnv("FG_INVERSE_THICKNESS_DIVISIONS", 5);
    private static final String OUTPUT_DIR = env(
        "FG_INVERSE_OUTPUT_DIR",
        new File("outputs/paper-20260715-fgmee/experiments/inverse_sensing").getAbsolutePath()
    );
    private static final String RUN_TAG = env("FG_INVERSE_RUN_TAG", "inverse_sensor_3d");

    private static final double[] TARGET_MM = new double[] {0.5, 1.0, 2.0};
    private static final double[] MATLAB_E_REF = new double[] {
        164.646372436052, 329.292744872103, 658.585489744207
    };
    private static final double[] MATLAB_M_REF = new double[] {
        0.170392625117427, 0.340785250234854, 0.681570500469709
    };
    private static int numericalCounter = 0;

    public static Model run() {
        validateConfiguration();
        new File(OUTPUT_DIR).mkdirs();

        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
        model.label(baseName() + ".mph");
        model.param().set("pLoad", Double.toString(PROBE_PRESSURE_PA) + "[Pa]");

        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").lengthUnit("m");
        for (int i = 0; i < NLAYER; i++) {
            String tag = "blk" + (i + 1);
            double z0 = -H / 2.0 + i * HLAYER;
            model.component("comp1").geom("geom1").create(tag, "Block");
            model.component("comp1").geom("geom1").feature(tag).set("base", "corner");
            model.component("comp1").geom("geom1").feature(tag).set("size", new String[] {
                Double.toString(L), Double.toString(W), Double.toString(HLAYER)
            });
            model.component("comp1").geom("geom1").feature(tag).set("pos", new String[] {
                "0", "0", Double.toString(z0)
            });
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
        for (int i = 0; i < NLAYER; i++) {
            double z0 = -H / 2.0 + i * HLAYER;
            double z1 = z0 + HLAYER;
            createBoxSelection(model, "sel_layer_" + (i + 1), 3,
                "-1e-9", "0.300000001", "-1e-9", "0.300000001",
                Double.toString(z0 - 1e-9), Double.toString(z1 + 1e-9));
            int nDomain = model.component("comp1").selection("sel_layer_" + (i + 1)).entities(3).length;
            if (nDomain != 1) {
                throw new IllegalStateException("Layer selection " + (i + 1)
                    + " contains " + nDomain + " domains; expected exactly one");
            }
        }

        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("U Vf0.6 reduced-property 3D diagnostic");
        model.component("comp1").material("mat1").selection().all();
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("youngsmodulus", Double.toString(YOUNG) + "[Pa]");
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("poissonsratio", Double.toString(NU));
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("density", Double.toString(RHO) + "[kg/m^3]");

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").prop("ShapeProperty")
            .set("order_displacement", "2s");
        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1").selection().named("sel_fixed");
        model.component("comp1").physics("solid").create("bndl1", "BoundaryLoad", 2);
        model.component("comp1").physics("solid").feature("bndl1").selection().named("sel_top");
        model.component("comp1").physics("solid").feature("bndl1").set("LoadType", "ForceArea");
        model.component("comp1").physics("solid").feature("bndl1")
            .set("FperArea", new String[] {"0", "0", "-pLoad"});

        createSweptMesh(model);
        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);

        System.out.println("INVERSE_SENSOR_CONFIG,probe_pressure_Pa," + PROBE_PRESSURE_PA
            + ",inplane_divisions," + INPLANE_DIVISIONS
            + ",thickness_divisions_per_layer," + THROUGH_THICKNESS_DIVISIONS
            + ",method,3d_solid_plus_local_open_circuit_constitutive_postprocess");
        model.study("std1").run();

        double probeWm = interpolateScalar(model, "w", 0.15, 0.15, 0.0);
        double probeAbsWmm = Math.abs(1000.0 * probeWm);
        if (!(probeAbsWmm > 0.0)) {
            throw new IllegalStateException("Probe displacement is zero or invalid: " + probeAbsWmm);
        }

        double c11 = YOUNG / (1.0 - NU * NU);
        double c12 = YOUNG * NU / (1.0 - NU * NU);
        double e31 = D31 * c11 + D32 * c12;
        double e32 = D31 * c12 + D32 * c11;
        // Keep the MATLAB implementation detail exactly: both correction
        // terms use eM(:,1); e31=e32 for this material, so it is immaterial.
        double gEffective = G33 - D31 * e31 - D32 * e31;
        double denominator = gEffective * R33 - K33 * K33;

        double[] strainX = new double[NLAYER];
        double[] strainY = new double[NLAYER];
        double[] temperatureProbe = new double[NLAYER];
        double[] phiProbe = new double[NLAYER];
        double[] psiProbe = new double[NLAYER];
        double[] phiThermalProbe = new double[NLAYER];
        double[] psiThermalProbe = new double[NLAYER];
        for (int i = 0; i < NLAYER; i++) {
            String selection = "sel_layer_" + (i + 1);
            strainX[i] = volumeAverage(model, "solid.eXX", selection);
            strainY[i] = volumeAverage(model, "solid.eYY", selection);
            double electricSource = e31 * strainX[i] + e32 * strainY[i];
            double magneticSource = Q31 * strainX[i] + Q32 * strainY[i];
            double electricField = -(R33 * electricSource - K33 * magneticSource) / denominator;
            double magneticField = (K33 * electricSource - gEffective * magneticSource) / denominator;
            phiProbe[i] = -electricField * HLAYER;
            psiProbe[i] = -magneticField * HLAYER;

            // The bundled MATLAB formulation solves the reciprocal static
            // temperature field from Ktu*u + Ktt*T = 0.  For this uniform
            // material and local layer DOF, that relation reduces exactly to
            // the following layer-average constitutive expression.
            temperatureProbe[i] = -(
                THERMO_COUPLING_1 * strainX[i] + THERMO_COUPLING_2 * strainY[i]
            ) / HEAT_CAPACITY;
            double electricSourceThermal = electricSource + PYRO_E * temperatureProbe[i];
            double magneticSourceThermal = magneticSource + PYRO_M * temperatureProbe[i];
            double electricFieldThermal = -(
                R33 * electricSourceThermal - K33 * magneticSourceThermal
            ) / denominator;
            double magneticFieldThermal = (
                K33 * electricSourceThermal - gEffective * magneticSourceThermal
            ) / denominator;
            phiThermalProbe[i] = -electricFieldThermal * HLAYER;
            psiThermalProbe[i] = -magneticFieldThermal * HLAYER;
        }

        writeLayerCsv(strainX, strainY, temperatureProbe, phiProbe, psiProbe,
            phiThermalProbe, psiThermalProbe, probeWm);
        writeSummaryCsv(probeAbsWmm, phiProbe, psiProbe, phiThermalProbe,
            psiThermalProbe, e31, e32, gEffective, denominator);

        System.out.println("INVERSE_SENSOR_PROBE,w_center_mm," + (1000.0 * probeWm)
            + ",phi_span," + span(phiProbe) + ",psi_span," + span(psiProbe)
            + ",phi_thermal_span," + span(phiThermalProbe)
            + ",psi_thermal_span," + span(psiThermalProbe)
            + ",e31," + e31 + ",g_effective," + gEffective
            + ",denominator," + denominator);
        return model;
    }

    private static void writeSummaryCsv(double probeAbsWmm, double[] phiProbe,
            double[] psiProbe, double[] phiThermalProbe, double[] psiThermalProbe,
            double e31, double e32, double gEffective, double denominator) {
        File path = new File(OUTPUT_DIR, baseName() + "_summary.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,inplane_divisions,thickness_divisions_per_layer,target_w_mm,calibrated_pressure_Pa,electric_span_zero_temperature_V,magnetic_span_zero_temperature_A,electric_span_thermo_corrected_V,magnetic_span_thermo_corrected_A,matlab_legacy_thermal_electric_V,matlab_legacy_thermal_magnetic_A,legacy_electric_relative_error_pct,legacy_magnetic_relative_error_pct,probe_abs_w_mm,e31,e32,g_effective,k33,r33,determinant,status,evidence_tier");
            double phiSpanProbe = span(phiProbe);
            double psiSpanProbe = span(psiProbe);
            double phiThermalSpanProbe = span(phiThermalProbe);
            double psiThermalSpanProbe = span(psiThermalProbe);
            for (int i = 0; i < TARGET_MM.length; i++) {
                double scale = TARGET_MM[i] / probeAbsWmm;
                double phi = Math.abs(phiSpanProbe * scale);
                double psi = Math.abs(psiSpanProbe * scale);
                double phiThermal = Math.abs(phiThermalSpanProbe * scale);
                double psiThermal = Math.abs(psiThermalSpanProbe * scale);
                double pressure = PROBE_PRESSURE_PA * scale;
                writer.println("inverse_CFFF_U_Vf06," + INPLANE_DIVISIONS + ","
                    + THROUGH_THICKNESS_DIVISIONS + "," + TARGET_MM[i] + "," + pressure
                    + "," + phi + "," + psi + "," + phiThermal + "," + psiThermal
                    + "," + MATLAB_E_REF[i] + "," + MATLAB_M_REF[i] + ","
                    + relativeErrorPct(phiThermal, MATLAB_E_REF[i]) + ","
                    + relativeErrorPct(psiThermal, MATLAB_M_REF[i]) + "," + probeAbsWmm
                    + "," + e31 + "," + e32 + "," + gEffective + "," + K33 + ","
                    + R33 + "," + denominator
                    + ",completed_nonisomorphic_3d_constitutive_postprocess,B");
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write inverse-sensor summary: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void writeLayerCsv(double[] strainX, double[] strainY,
            double[] temperatureProbe, double[] phiProbe, double[] psiProbe,
            double[] phiThermalProbe, double[] psiThermalProbe, double probeWm) {
        File path = new File(OUTPUT_DIR, baseName() + "_layers.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("layer,z_mid_m,probe_pressure_Pa,probe_w_center_mm,avg_eXX,avg_eYY,temperature_reciprocal_K,phi_drop_zero_temperature,psi_drop_zero_temperature,phi_drop_thermo_corrected,psi_drop_thermo_corrected");
            for (int i = 0; i < NLAYER; i++) {
                double zMid = -H / 2.0 + (i + 0.5) * HLAYER;
                writer.println((i + 1) + "," + zMid + "," + PROBE_PRESSURE_PA + ","
                    + (1000.0 * probeWm) + "," + strainX[i] + "," + strainY[i]
                    + "," + temperatureProbe[i] + "," + phiProbe[i] + "," + psiProbe[i]
                    + "," + phiThermalProbe[i] + "," + psiThermalProbe[i]);
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write inverse-sensor layer data: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void createSweptMesh(Model model) {
        int[] bottomFaceEntities = model.component("comp1").selection("sel_bottom").entities(2);
        int[] bottomEdgeEntities = model.component("comp1").selection("sel_bottom_edges").entities(1);
        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").create("map1", "Map");
        model.component("comp1").mesh("mesh1").feature("map1").selection().set(bottomFaceEntities);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .selection().set(bottomEdgeEntities);
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .set("numelem", INPLANE_DIVISIONS);
        model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
        model.component("comp1").mesh("mesh1").feature("swe1").selection("sourceface")
            .set(bottomFaceEntities);
        model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
        model.component("comp1").mesh("mesh1").feature("swe1").set("sweeppath", "straight");
        model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1")
            .set("numelem", THROUGH_THICKNESS_DIVISIONS);
        model.component("comp1").mesh("mesh1").run();
        System.out.println("INVERSE_SENSOR_MESH,total_elements,"
            + model.component("comp1").mesh("mesh1").getNumElem());
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
        throw new IllegalStateException("Unexpected interpolation shape for " + expression);
    }

    private static double volumeAverage(Model model, String expression, String selection) {
        String tag = "av" + (++numericalCounter);
        model.result().numerical().create(tag, "AvVolume");
        model.result().numerical(tag).selection().named(selection);
        model.result().numerical(tag).set("expr", new String[] {expression});
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length >= 1 && values[0].length >= 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected volume-average shape for " + expression
            + " on " + selection);
    }

    private static double span(double[] values) {
        double min = Double.POSITIVE_INFINITY;
        double max = Double.NEGATIVE_INFINITY;
        for (double value : values) {
            min = Math.min(min, value);
            max = Math.max(max, value);
        }
        return max - min;
    }

    private static double relativeErrorPct(double value, double reference) {
        return 100.0 * Math.abs(value - reference) / Math.abs(reference);
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

    private static String baseName() {
        return "comsol_" + RUN_TAG.replaceAll("[^A-Za-z0-9_\\-]+", "_");
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

    private static void validateConfiguration() {
        if (PROBE_PRESSURE_PA <= 0.0 || INPLANE_DIVISIONS < 1
                || THROUGH_THICKNESS_DIVISIONS < 1) {
            throw new IllegalArgumentException("Pressure and mesh divisions must be positive");
        }
    }

    public static void main(String[] args) {
        run();
    }
}
