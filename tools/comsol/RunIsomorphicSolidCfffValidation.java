import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/**
 * Matched 3D-solid counterpart of matlab/run_isomorphic_solid_cfff.m.
 *
 * <p>Both solvers use a 300 mm square, 6 mm thick, ten-domain CFFF solid,
 * quadratic displacement interpolation, isotropic E/nu, and prescribed
 * in-plane ExternalStress tensors in only the two outer material layers.
 * This model deliberately removes field-equation and plate/solid differences
 * so the remaining discrepancy is a numerical implementation check.</p>
 */
public class RunIsomorphicSolidCfffValidation {
    private static final double L = 0.300;
    private static final double W = 0.300;
    private static final double H = 0.006;
    private static final double HLAYER = 0.0006;
    private static final int NLAYER = 10;
    private static final double YOUNG = 1.206e11;
    private static final double NU = 0.3398;
    private static final double RHO = 5600.0;

    private static final int INPLANE = intEnv("FG_ISO_INPLANE_DIVISIONS", 10);
    private static final int THICKNESS_PER_LAYER = intEnv("FG_ISO_THICKNESS_PER_LAYER", 1);
    private static final double BOTTOM_STRESS = doubleEnv("FG_ISO_BOTTOM_STRESS_PA", 4.934e6);
    private static final double TOP_STRESS = doubleEnv("FG_ISO_TOP_STRESS_PA", -4.934e6);
    private static final String LOAD_CASE = env("FG_ISO_LOAD_CASE", "electric_equivalent_stress");
    private static final String RUN_TAG = env("FG_ISO_RUN_TAG", LOAD_CASE + "_" + INPLANE + "x");
    private static final String OUTPUT_DIR = env(
        "FG_ISO_OUTPUT_DIR",
        new File("outputs/paper-20260715-fgmee/experiments/isomorphic_solid/comsol").getAbsolutePath()
    );
    private static int numericalCounter = 0;

    public static Model run() {
        if (INPLANE < 1 || THICKNESS_PER_LAYER < 1) {
            throw new IllegalArgumentException("Mesh division counts must be positive");
        }
        new File(OUTPUT_DIR).mkdirs();
        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
        model.label(baseName() + ".mph");

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
        createBoxSelection(model, "sel_bottom_outer", 2,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        createBoxSelection(model, "sel_bottom_edges", 1,
            "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");

        int fixedCount = model.component("comp1").selection("sel_fixed").entities(2).length;
        int bottomCount = model.component("comp1").selection("sel_bottom_dom").entities(3).length;
        int topCount = model.component("comp1").selection("sel_top_dom").entities(3).length;
        if (fixedCount < 1 || bottomCount != 1 || topCount != 1) {
            throw new IllegalStateException("Unsafe selection counts: fixed=" + fixedCount
                + ", bottom=" + bottomCount + ", top=" + topCount);
        }

        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("Matched isotropic solid material");
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

        createExternalStress(model, "exs_bottom", "sel_bottom_dom", BOTTOM_STRESS);
        createExternalStress(model, "exs_top", "sel_top_dom", TOP_STRESS);
        createSweptMesh(model);

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
        System.out.println("ISOMORPHIC_COMSOL_CONFIG,load_case," + LOAD_CASE
            + ",inplane," + INPLANE + ",thickness_per_layer," + THICKNESS_PER_LAYER
            + ",bottom_stress_Pa," + BOTTOM_STRESS + ",top_stress_Pa," + TOP_STRESS
            + ",fixed_faces," + fixedCount + ",bottom_domains," + bottomCount
            + ",top_domains," + topCount);
        model.study("std1").run();

        double centerMm = 1000.0 * interpolateScalar(model, "w", 0.15, 0.15, 0.0);
        double freeMidMm = 1000.0 * interpolateScalar(model, "w", L - 1e-9, 0.15, 0.0);
        double totalElements = model.component("comp1").mesh("mesh1").getNumElem();
        writeSummary(centerMm, freeMidMm, totalElements, fixedCount, bottomCount, topCount);
        writeCenterline(model);
        System.out.println("ISOMORPHIC_COMSOL_RESULT,load_case," + LOAD_CASE
            + ",w_center_mm," + centerMm + ",w_free_mid_mm," + freeMidMm
            + ",total_elements," + totalElements);
        return model;
    }

    private static void createExternalStress(Model model, String tag, String selection, double stress) {
        model.component("comp1").physics("solid").feature("lemm1")
            .create(tag, "ExternalStress", 3);
        model.component("comp1").physics("solid").feature("lemm1").feature(tag)
            .selection().named(selection);
        model.component("comp1").physics("solid").feature("lemm1").feature(tag)
            .set("StressInputType", "StressTensorMaterial");
        model.component("comp1").physics("solid").feature("lemm1").feature(tag)
            .set("ContributionType", "Stress");
        String s = Double.toString(stress) + "[Pa]";
        model.component("comp1").physics("solid").feature("lemm1").feature(tag)
            .set("Sext", new String[] {s, "0", "0", "0", s, "0", "0", "0", "0"});
    }

    private static void createSweptMesh(Model model) {
        int[] sourceFaces = model.component("comp1").selection("sel_bottom_outer").entities(2);
        int[] sourceEdges = model.component("comp1").selection("sel_bottom_edges").entities(1);
        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").create("map1", "Map");
        model.component("comp1").mesh("mesh1").feature("map1").selection().set(sourceFaces);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .selection().set(sourceEdges);
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
            .set("numelem", INPLANE);
        model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
        model.component("comp1").mesh("mesh1").feature("swe1").selection("sourceface")
            .set(sourceFaces);
        model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
        model.component("comp1").mesh("mesh1").feature("swe1").set("sweeppath", "straight");
        model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1")
            .set("numelem", THICKNESS_PER_LAYER);
        model.component("comp1").mesh("mesh1").run();
    }

    private static double interpolateScalar(Model model, String expr, double x, double y, double z) {
        String tag = "interp" + (++numericalCounter);
        model.result().numerical().create(tag, "Interp");
        model.result().numerical(tag).set("expr", new String[] {expr});
        model.result().numerical(tag).set("coord", new double[][] {{x}, {y}, {z}});
        double[][] value = model.result().numerical(tag).getReal();
        if (value.length == 0 || value[0].length == 0) {
            throw new IllegalStateException("No interpolation value for " + expr);
        }
        return value[0][0];
    }

    private static void writeSummary(double centerMm, double freeMidMm, double totalElements,
            int fixedCount, int bottomCount, int topCount) {
        File path = new File(OUTPUT_DIR, baseName() + "_summary.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("load_case,inplane_divisions,thickness_elements_per_physical_layer,bottom_stress_Pa,top_stress_Pa,w_center_mm,w_free_mid_mm,total_elements,fixed_face_count,bottom_domain_count,top_domain_count,status");
            writer.println(LOAD_CASE + "," + INPLANE + "," + THICKNESS_PER_LAYER + ","
                + BOTTOM_STRESS + "," + TOP_STRESS + "," + centerMm + "," + freeMidMm
                + "," + totalElements + "," + fixedCount + "," + bottomCount + ","
                + topCount + ",completed");
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void writeCenterline(Model model) {
        File path = new File(OUTPUT_DIR, baseName() + "_centerline.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("x_over_a,x_m,y_m,z_m,w_mm");
            for (int i = 0; i <= 10; i++) {
                double x = L * i / 10.0;
                double sampleX = i == 10 ? x - 1e-9 : x;
                double wMm = 1000.0 * interpolateScalar(model, "w", sampleX, W/2.0, 0.0);
                writer.println((i / 10.0) + "," + x + "," + (W/2.0) + ",0," + wMm);
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void createBoxSelection(Model model, String tag, int dim,
            String xmin, String xmax, String ymin, String ymax, String zmin, String zmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(dim));
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", xmin);
        model.component("comp1").selection(tag).set("xmax", xmax);
        model.component("comp1").selection(tag).set("ymin", ymin);
        model.component("comp1").selection(tag).set("ymax", ymax);
        model.component("comp1").selection(tag).set("zmin", zmin);
        model.component("comp1").selection(tag).set("zmax", zmax);
    }

    private static String baseName() {
        return "comsol_isomorphic_" + RUN_TAG.replaceAll("[^A-Za-z0-9_\\-]+", "_");
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.trim().isEmpty() ? defaultValue : value.trim();
    }

    private static int intEnv(String name, int defaultValue) {
        String value = env(name, "");
        return value.isEmpty() ? defaultValue : Integer.parseInt(value);
    }

    private static double doubleEnv(String name, double defaultValue) {
        String value = env(name, "");
        return value.isEmpty() ? defaultValue : Double.parseDouble(value);
    }

    public static void main(String[] args) {
        run();
    }
}
