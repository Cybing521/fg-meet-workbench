import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/**
 * Independent 3D COMSOL validation for the CFFF electric-actuation case.
 *
 * <p>The MATLAB shell model stores one generalized electric potential per
 * material layer and prescribes -V in layer 1 and +V in layer 10.  Because
 * each layer field is defined in its local thickness direction, this is
 * represented here by two independently electroded outer layers: each inner
 * electrode is grounded and each exterior electrode is set to +V.  This
 * produces opposite through-thickness electric fields in the bottom and top
 * layers without inserting the precomputed 4.934 MPa equivalent load.</p>
 */
public class RunDirectElectroCfffValidation {
    private static final double L = 0.300;
    private static final double W = 0.300;
    private static final double H = 0.006;
    private static final double HLAYER = 0.0006;
    private static final int NLAYER = 10;

    private static final double YOUNG = 1.206e11;
    private static final double NU = 0.3398;
    private static final double SHEAR = 4.500e10;
    private static final double RHO = 5600.0;
    private static final double D31 = -5.404e-11;
    private static final double D32 = -5.404e-11;
    private static final double EPS_T_ABS = 9.203e-9;
    private static final double EPS0 = 8.8541878128e-12;

    private static final double VOLTAGE = doubleEnv("FG_DIRECT_VOLTAGE", 300.0);
    private static final int INPLANE_DIVISIONS = intEnv("FG_DIRECT_INPLANE_DIVISIONS", 15);
    private static final int THROUGH_THICKNESS_DIVISIONS = intEnv("FG_DIRECT_THICKNESS_DIVISIONS", 10);
    private static final String OUTPUT_DIR = env(
        "FG_DIRECT_OUTPUT_DIR",
        new File("outputs/paper-20260715-fgmee/experiments/comsol").getAbsolutePath()
    );
    private static final String RUN_TAG = env("FG_DIRECT_RUN_TAG", "direct_electro_300V");

    private static int numericalCounter = 0;

    public static Model run() {
        new File(OUTPUT_DIR).mkdirs();

        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
        model.label(baseName() + ".mph");

        model.param().set("L", "0.3[m]");
        model.param().set("W", "0.3[m]");
        model.param().set("H", "0.006[m]");
        model.param().set("hlay", "0.0006[m]");
        model.param().set("Vlay", Double.toString(VOLTAGE) + "[V]");

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
        createBoxSelection(model, "sel_bottom_dom", 3,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002399999");
        createBoxSelection(model, "sel_top_dom", 3,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "0.002399999", "0.003000001");
        createBoxSelection(model, "sel_inner_dom", 3,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.002400001", "0.002400001");
        createUnionSelection(model, "sel_outer_dom", 3, new String[] {
            "sel_bottom_dom", "sel_top_dom"
        });

        createBoxSelection(model, "sel_bottom_outer", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        createBoxSelection(model, "sel_bottom_inner", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.002400001", "-0.002399999");
        createBoxSelection(model, "sel_top_inner", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "0.002399999", "0.002400001");
        createBoxSelection(model, "sel_top_outer", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "0.002999999", "0.003000001");
        createBoxSelection(model, "sel_bottom_edges", 1,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");

        createUnionSelection(model, "sel_outer_electrodes", 2, new String[] {
            "sel_bottom_outer", "sel_top_outer"
        });
        createUnionSelection(model, "sel_inner_electrodes", 2, new String[] {
            "sel_bottom_inner", "sel_top_inner"
        });

        int fixedCount = model.component("comp1").selection("sel_fixed").entities(2).length;
        int bottomDomainCount = model.component("comp1").selection("sel_bottom_dom").entities(3).length;
        int topDomainCount = model.component("comp1").selection("sel_top_dom").entities(3).length;
        int outerDomainCount = model.component("comp1").selection("sel_outer_dom").entities(3).length;
        int outerElectrodeCount = model.component("comp1").selection("sel_outer_electrodes").entities(2).length;
        int innerElectrodeCount = model.component("comp1").selection("sel_inner_electrodes").entities(2).length;
        System.out.println("DIRECT_ELECTRO_SELECTIONS,fixed," + fixedCount
            + ",bottom_domain," + bottomDomainCount
            + ",top_domain," + topDomainCount
            + ",outer_domains," + outerDomainCount
            + ",outer_electrodes," + outerElectrodeCount
            + ",inner_electrodes," + innerElectrodeCount);
        if (fixedCount == 0 || bottomDomainCount != 1 || topDomainCount != 1 || outerDomainCount != 2
                || outerElectrodeCount != 2 || innerElectrodeCount != 2) {
            throw new IllegalStateException("Unexpected geometry selection counts; direct model is not safe to solve");
        }

        createMaterial(model);

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").prop("ShapeProperty").set("order_displacement", "2s");

        model.component("comp1").physics("solid").create("pzmb", "PiezoelectricMaterialModel");
        model.component("comp1").physics("solid").feature("pzmb").selection().named("sel_bottom_dom");
        configurePiezoFeature(model, "pzmb");
        model.component("comp1").physics("solid").create("pzmt", "PiezoelectricMaterialModel");
        model.component("comp1").physics("solid").feature("pzmt").selection().named("sel_top_dom");
        configurePiezoFeature(model, "pzmt");

        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1").selection().named("sel_fixed");

        model.component("comp1").physics().create("es", "Electrostatics", "geom1");
        model.component("comp1").physics("es").selection().named("sel_outer_dom");
        model.component("comp1").physics("es").prop("ShapeProperty").set("order_electricpotential", "2");
        model.component("comp1").physics("es").create("ccnpb", "ChargeConservationPiezo");
        model.component("comp1").physics("es").feature("ccnpb").selection().named("sel_bottom_dom");
        model.component("comp1").physics("es").create("ccnpt", "ChargeConservationPiezo");
        model.component("comp1").physics("es").feature("ccnpt").selection().named("sel_top_dom");
        model.component("comp1").physics("es").create("gnd1", "Ground", 2);
        model.component("comp1").physics("es").feature("gnd1").selection().named("sel_inner_electrodes");
        model.component("comp1").physics("es").create("pot1", "ElectricPotential", 2);
        model.component("comp1").physics("es").feature("pot1").selection().named("sel_outer_electrodes");
        model.component("comp1").physics("es").feature("pot1").set("V0", "Vlay");

        model.component("comp1").multiphysics().create("pze1", "PiezoelectricEffect", 3);
        model.component("comp1").multiphysics("pze1").set("Solid_physics", "solid");
        model.component("comp1").multiphysics("pze1").set("Electrostatics_physics", "es");

        createSweptMesh(model);

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
        model.study("std1").feature("stat").setSolveFor("/physics/es", true);
        model.study("std1").feature("stat").setSolveFor("/multiphysics/pze1", true);

        System.out.println("DIRECT_ELECTRO_CONFIG,voltage_V," + VOLTAGE
            + ",inplane_divisions," + INPLANE_DIVISIONS
            + ",through_thickness_divisions," + THROUGH_THICKNESS_DIVISIONS
            + ",d31_m_per_V," + D31 + ",d32_m_per_V," + D32
            + ",epsilonT_F_per_m," + EPS_T_ABS);
        model.study("std1").run();

        double wCenterM = interpolateScalar(model, "w", 0.15, 0.15, 0.0);
        double wFreeMidM = interpolateScalar(model, "w", 0.30 - 1e-9, 0.15, 0.0);
        double vBottomOuter = interpolateScalar(model, "V", 0.15, 0.15, -0.003 + 1e-9);
        double vBottomInner = interpolateScalar(model, "V", 0.15, 0.15, -0.0024 - 1e-9);
        double vTopInner = interpolateScalar(model, "V", 0.15, 0.15, 0.0024 + 1e-9);
        double vTopOuter = interpolateScalar(model, "V", 0.15, 0.15, 0.003 - 1e-9);
        double ezBottom = interpolateScalar(model, "es.Ez", 0.15, 0.15, -0.0027);
        double ezTop = interpolateScalar(model, "es.Ez", 0.15, 0.15, 0.0027);

        double wCenterMm = 1000.0 * wCenterM;
        double wFreeMidMm = 1000.0 * wFreeMidM;
        double matlabReferenceMm = -0.0522570949;
        double qianReferenceMm = -0.0523;
        double relativeErrorMatlabPct = relativeErrorPct(wCenterMm, matlabReferenceMm);
        double relativeErrorQianPct = relativeErrorPct(wCenterMm, qianReferenceMm);

        writeSummaryCsv(wCenterMm, wFreeMidMm, matlabReferenceMm, qianReferenceMm,
            relativeErrorMatlabPct, relativeErrorQianPct,
            vBottomOuter, vBottomInner, vTopInner, vTopOuter, ezBottom, ezTop);

        System.out.println("DIRECT_ELECTRO_RESULT,w_center_mm," + wCenterMm
            + ",w_free_mid_mm," + wFreeMidMm
            + ",matlab_reference_mm," + matlabReferenceMm
            + ",relative_error_matlab_pct," + relativeErrorMatlabPct
            + ",qian_reference_mm," + qianReferenceMm
            + ",relative_error_qian_pct," + relativeErrorQianPct
            + ",Ez_bottom_Vpm," + ezBottom + ",Ez_top_Vpm," + ezTop);

        return model;
    }

    private static void createMaterial(Model model) {
        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("Qian U Vf0.6 MEE material from case file");
        model.component("comp1").material("mat1").selection().all();
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("youngsmodulus", Double.toString(YOUNG) + "[Pa]");
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("poissonsratio", Double.toString(NU));
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("density", Double.toString(RHO) + "[kg/m^3]");

        model.component("comp1").material("mat1").propertyGroup()
            .create("StrainCharge", "Strain-charge form");
        model.component("comp1").material("mat1").propertyGroup("StrainCharge")
            .set("sE", isotropicCompliance());
        model.component("comp1").material("mat1").propertyGroup("StrainCharge")
            .set("dET", piezoStrainCharge());
        double epsr = EPS_T_ABS / EPS0;
        model.component("comp1").material("mat1").propertyGroup("StrainCharge")
            .set("epsilonrT", new String[] {
                Double.toString(epsr), "0", "0",
                "0", Double.toString(epsr), "0",
                "0", "0", Double.toString(epsr)
            });
    }

    private static void configurePiezoFeature(Model model, String tag) {
        model.component("comp1").physics("solid").feature(tag)
            .set("ConstitutiveRelation", "StrainCharge");
        model.component("comp1").physics("solid").feature(tag).set("sE_mat", "from_mat");
        model.component("comp1").physics("solid").feature(tag).set("dET_mat", "from_mat");
        model.component("comp1").physics("solid").feature(tag).set("epsilonrT_mat", "from_mat");
    }

    private static String[] isotropicCompliance() {
        double a = 1.0 / YOUNG;
        double b = -NU / YOUNG;
        double g = 1.0 / SHEAR;
        return new String[] {
            unit(a, "1/Pa"), unit(b, "1/Pa"), unit(b, "1/Pa"), "0[1/Pa]", "0[1/Pa]", "0[1/Pa]",
            unit(b, "1/Pa"), unit(a, "1/Pa"), unit(b, "1/Pa"), "0[1/Pa]", "0[1/Pa]", "0[1/Pa]",
            unit(b, "1/Pa"), unit(b, "1/Pa"), unit(a, "1/Pa"), "0[1/Pa]", "0[1/Pa]", "0[1/Pa]",
            "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", unit(g, "1/Pa"), "0[1/Pa]", "0[1/Pa]",
            "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", unit(g, "1/Pa"), "0[1/Pa]",
            "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", "0[1/Pa]", unit(g, "1/Pa")
        };
    }

    private static String[] piezoStrainCharge() {
        return new String[] {
            "0[C/N]", "0[C/N]", unit(D31, "C/N"),
            "0[C/N]", "0[C/N]", unit(D32, "C/N"),
            "0[C/N]", "0[C/N]", "0[C/N]",
            "0[C/N]", "0[C/N]", "0[C/N]",
            "0[C/N]", "0[C/N]", "0[C/N]",
            "0[C/N]", "0[C/N]", "0[C/N]"
        };
    }

    private static void createSweptMesh(Model model) {
        int[] bottomFaceEntities = model.component("comp1").selection("sel_bottom_outer").entities(2);
        int[] bottomEdgeEntities = model.component("comp1").selection("sel_bottom_edges").entities(1);
        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").create("map1", "Map");
        model.component("comp1").mesh("mesh1").feature("map1").selection().set(bottomFaceEntities);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1").selection()
            .set(bottomEdgeEntities);
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
        System.out.println("DIRECT_ELECTRO_MESH,total_elements,"
            + model.component("comp1").mesh("mesh1").getNumElem());
    }

    private static double interpolateScalar(Model model, String expression, double x, double y, double z) {
        String tag = "interp" + (++numericalCounter);
        model.result().numerical().create(tag, "Interp");
        model.result().numerical(tag).set("expr", new String[] {expression});
        model.result().numerical(tag).set("coord", new double[][] {
            {x}, {y}, {z}
        });
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length == 1 && values[0].length >= 1) {
            return values[0][0];
        }
        if (values.length >= 1 && values[0].length == 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected interpolation shape for " + expression);
    }

    private static void writeSummaryCsv(double wCenterMm, double wFreeMidMm,
            double matlabReferenceMm, double qianReferenceMm,
            double relativeErrorMatlabPct, double relativeErrorQianPct,
            double vBottomOuter, double vBottomInner, double vTopInner, double vTopOuter,
            double ezBottom, double ezTop) {
        File path = new File(OUTPUT_DIR, baseName() + "_summary.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,voltage_layer_V,w_center_mm,w_free_mid_mm,matlab_reference_mm,qian_reference_mm,relative_error_matlab_pct,relative_error_qian_pct,V_bottom_outer,V_bottom_inner,V_top_inner,V_top_outer,Ez_bottom_Vpm,Ez_top_Vpm,status");
            writer.println("direct_electro_CFFF_U_Vf06," + VOLTAGE + "," + wCenterMm + "," + wFreeMidMm
                + "," + matlabReferenceMm + "," + qianReferenceMm
                + "," + relativeErrorMatlabPct + "," + relativeErrorQianPct
                + "," + vBottomOuter + "," + vBottomInner + "," + vTopInner + "," + vTopOuter
                + "," + ezBottom + "," + ezTop + ",completed");
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write direct electro summary: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static double relativeErrorPct(double value, double reference) {
        return 100.0 * Math.abs(value - reference) / Math.abs(reference);
    }

    private static String unit(double value, String unitName) {
        return Double.toString(value) + "[" + unitName + "]";
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

    private static void createUnionSelection(Model model, String tag, int entityDim, String[] inputs) {
        model.component("comp1").selection().create(tag, "Union");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(entityDim));
        model.component("comp1").selection(tag).set("input", inputs);
    }

    private static String baseName() {
        return "comsol_" + RUN_TAG.replaceAll("[^A-Za-z0-9_\\-]+", "_");
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        if (value == null || value.trim().length() == 0) {
            return defaultValue;
        }
        return value.trim();
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
        run();
    }
}
