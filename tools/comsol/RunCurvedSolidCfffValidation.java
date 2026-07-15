import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/** Independent 3D-solid check of the R=0.4 m CFFF cylindrical panel. */
public class RunCurvedSolidCfffValidation {
    private static final double L = 0.300;
    private static final double ARC = 0.300;
    private static final double H = 0.006;
    private static final double R = doubleEnv("FG_CURVED_RADIUS_M", 0.4);
    private static final double RIN = R - H / 2.0;
    private static final double ROUT = R + H / 2.0;
    private static final double THETA = ARC / R;
    private static final double THETA_DEG = THETA * 180.0 / Math.PI;
    private static final double YOUNG = 1.206e11;
    private static final double NU = 0.3398;
    private static final double RHO = 5600.0;
    private static final double PRESSURE = doubleEnv("FG_CURVED_PRESSURE_PA", 15000.0);
    private static final int AXIAL_DIV = intEnv("FG_CURVED_AXIAL_DIVISIONS", 20);
    private static final int CIRC_DIV = intEnv("FG_CURVED_CIRC_DIVISIONS", 20);
    private static final int THICK_DIV = intEnv("FG_CURVED_THICKNESS_DIVISIONS", 10);
    private static final String RUN_TAG = env("FG_CURVED_RUN_TAG", "U_R0p4_20x20x10");
    private static final String OUTPUT_DIR = env(
        "FG_CURVED_OUTPUT_DIR",
        new File("outputs/paper-20260715-fgmee/experiments/curvature_fg/comsol").getAbsolutePath()
    );
    private static int numericalCounter = 0;

    public static Model run() {
        if (R <= H / 2.0 || AXIAL_DIV < 1 || CIRC_DIV < 1 || THICK_DIV < 1) {
            throw new IllegalArgumentException("Invalid radius or mesh divisions");
        }
        new File(OUTPUT_DIR).mkdirs();
        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
        model.label(baseName() + ".mph");

        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").lengthUnit("m");
        model.component("comp1").geom("geom1").create("wp1", "WorkPlane");
        model.component("comp1").geom("geom1").feature("wp1").set("quickplane", "xz");
        model.component("comp1").geom("geom1").feature("wp1").geom()
            .create("r1", "Rectangle");
        model.component("comp1").geom("geom1").feature("wp1").geom().feature("r1")
            .set("base", "corner");
        model.component("comp1").geom("geom1").feature("wp1").geom().feature("r1")
            .set("pos", new String[] {"0", Double.toString(RIN)});
        model.component("comp1").geom("geom1").feature("wp1").geom().feature("r1")
            .set("size", new String[] {Double.toString(L), Double.toString(H)});
        model.component("comp1").geom("geom1").create("rev1", "Revolve");
        model.component("comp1").geom("geom1").feature("rev1").set("revolvefrom", "workplane");
        model.component("comp1").geom("geom1").feature("rev1").set("workplane", "wp1");
        model.component("comp1").geom("geom1").feature("rev1").selection("input")
            .set("wp1.r1");
        model.component("comp1").geom("geom1").feature("rev1").set("angtype", "specang");
        model.component("comp1").geom("geom1").feature("rev1").set("angle1", "0");
        model.component("comp1").geom("geom1").feature("rev1")
            .set("angle2", Double.toString(THETA_DEG));
        model.component("comp1").geom("geom1").feature("rev1").set("axistype", "2d");
        model.component("comp1").geom("geom1").feature("rev1").set("pos", new String[] {"0", "0"});
        model.component("comp1").geom("geom1").feature("rev1").set("axis", new String[] {"1", "0"});
        model.component("comp1").geom("geom1").run();

        double eps = 1e-8;
        createBoxSelection(model, "sel_theta0_face", 2,
            -eps, L + eps, -eps, eps, RIN - eps, ROUT + eps);
        createBoxSelection(model, "sel_axial_inner", 1,
            -eps, L + eps, -eps, eps, RIN - eps, RIN + eps);
        createBoxSelection(model, "sel_axial_outer", 1,
            -eps, L + eps, -eps, eps, ROUT - eps, ROUT + eps);
        createUnionSelection(model, "sel_axial_edges", 1,
            new String[] {"sel_axial_inner", "sel_axial_outer"});
        createBoxSelection(model, "sel_radial_x0", 1,
            -eps, eps, -eps, eps, RIN - eps, ROUT + eps);
        createBoxSelection(model, "sel_radial_xL", 1,
            L - eps, L + eps, -eps, eps, RIN - eps, ROUT + eps);
        createUnionSelection(model, "sel_radial_edges", 1,
            new String[] {"sel_radial_x0", "sel_radial_xL"});
        createCylinderSelection(model, "sel_outer_face", 2, ROUT - eps, ROUT + eps, eps);
        createCylinderSelection(model, "sel_inner_face", 2, RIN - eps, RIN + eps, eps);

        int theta0Count = model.component("comp1").selection("sel_theta0_face").entities(2).length;
        int axialEdgeCount = model.component("comp1").selection("sel_axial_edges").entities(1).length;
        int radialEdgeCount = model.component("comp1").selection("sel_radial_edges").entities(1).length;
        int outerCount = model.component("comp1").selection("sel_outer_face").entities(2).length;
        int innerCount = model.component("comp1").selection("sel_inner_face").entities(2).length;
        if (theta0Count != 1 || axialEdgeCount != 2 || radialEdgeCount != 2
                || outerCount != 1 || innerCount != 1) {
            throw new IllegalStateException("Unsafe curved selections: theta0=" + theta0Count
                + ", axialEdges=" + axialEdgeCount + ", radialEdges=" + radialEdgeCount
                + ", outer=" + outerCount + ", inner=" + innerCount);
        }

        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("U Vf0.6 isotropic reduced material");
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
        model.component("comp1").physics("solid").feature("fix1")
            .selection().named("sel_theta0_face");
        model.component("comp1").physics("solid").create("load1", "BoundaryLoad", 2);
        model.component("comp1").physics("solid").feature("load1")
            .selection().named("sel_outer_face");
        model.component("comp1").physics("solid").feature("load1")
            .set("LoadType", "FollowerPressure");
        model.component("comp1").physics("solid").feature("load1")
            .set("FollowerPressure", Double.toString(PRESSURE) + "[Pa]");

        createMappedSweptMesh(model);
        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
        System.out.println("CURVED_COMSOL_CONFIG,radius_m," + R + ",theta_rad," + THETA
            + ",pressure_Pa," + PRESSURE + ",axial_div," + AXIAL_DIV
            + ",circ_div," + CIRC_DIV + ",thickness_div," + THICK_DIV
            + ",theta0_faces," + theta0Count + ",outer_faces," + outerCount);
        model.study("std1").run();

        double thetaCenter = THETA / 2.0;
        // Positive revolve angle about +x follows the right-hand rule, so the
        // generated sector occupies negative global y from the x-z source plane.
        double centerY = -R * Math.sin(thetaCenter);
        double centerZ = R * Math.cos(thetaCenter);
        String radialExpr = "-v*sin(" + thetaCenter + ")+w*cos(" + thetaCenter + ")";
        double centerRadialMm = 1000.0 * interpolateScalar(
            model, radialExpr, L / 2.0, centerY, centerZ);
        double centerMagnitudeMm = 1000.0 * interpolateScalar(
            model, "sqrt(u^2+v^2+w^2)", L / 2.0, centerY, centerZ);
        double totalElements = model.component("comp1").mesh("mesh1").getNumElem();
        writeSummary(centerRadialMm, centerMagnitudeMm, totalElements,
            theta0Count, axialEdgeCount, radialEdgeCount, outerCount, innerCount);
        writeMidArc(model);
        System.out.println("CURVED_COMSOL_RESULT,w_center_radial_mm," + centerRadialMm
            + ",u_center_magnitude_mm," + centerMagnitudeMm
            + ",total_elements," + totalElements);
        return model;
    }

    private static void createMappedSweptMesh(Model model) {
        int[] sourceFaces = model.component("comp1").selection("sel_theta0_face").entities(2);
        int[] axialEdges = model.component("comp1").selection("sel_axial_edges").entities(1);
        int[] radialEdges = model.component("comp1").selection("sel_radial_edges").entities(1);
        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").create("map1", "Map");
        model.component("comp1").mesh("mesh1").feature("map1").selection().set(sourceFaces);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis_ax", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis_ax")
            .selection().set(axialEdges);
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis_ax")
            .set("numelem", AXIAL_DIV);
        model.component("comp1").mesh("mesh1").feature("map1").create("dis_th", "Distribution");
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis_th")
            .selection().set(radialEdges);
        model.component("comp1").mesh("mesh1").feature("map1").feature("dis_th")
            .set("numelem", THICK_DIV);
        model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
        model.component("comp1").mesh("mesh1").feature("swe1").selection("sourceface")
            .set(sourceFaces);
        model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
        model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
        model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1")
            .set("numelem", CIRC_DIV);
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

    private static void writeMidArc(Model model) {
        File path = new File(OUTPUT_DIR, baseName() + "_midarc.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("theta_over_span,theta_rad,x_m,y_m,z_m,radial_displacement_mm");
            for (int i = 0; i <= 10; i++) {
                double theta = THETA * i / 10.0;
                double sampleTheta = i == 10 ? theta - 1e-9 : theta;
                double y = -R * Math.sin(sampleTheta);
                double z = R * Math.cos(sampleTheta);
                String expr = "-v*sin(" + sampleTheta + ")+w*cos(" + sampleTheta + ")";
                double radialMm;
                try {
                    radialMm = 1000.0 * interpolateScalar(model, expr, L/2.0, y, z);
                } catch (RuntimeException ex) {
                    // A coarse curved serendipity mesh can move higher-order
                    // geometry nodes enough that an exact analytical arc point
                    // falls just outside the discrete element. Preserve the
                    // solved model and mark only that optional profile point.
                    radialMm = Double.NaN;
                    System.out.println("CURVED_COMSOL_MIDARC_POINT_SKIPPED,index," + i
                        + ",theta_rad," + sampleTheta + ",reason,interpolation_outside_mesh");
                }
                writer.println((i / 10.0) + "," + theta + "," + (L/2.0) + ","
                    + y + "," + z + "," + radialMm);
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void writeSummary(double radialMm, double magnitudeMm, double totalElements,
            int theta0Count, int axialEdgeCount, int radialEdgeCount,
            int outerCount, int innerCount) {
        File path = new File(OUTPUT_DIR, baseName() + "_summary.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,radius_m,arc_length_m,theta_span_rad,pressure_Pa,axial_divisions,circumferential_divisions,thickness_divisions,w_center_radial_mm,u_center_magnitude_mm,total_elements,fixed_face_count,axial_edge_count,radial_edge_count,outer_face_count,inner_face_count,status");
            writer.println("curved_CFFF_U_R0p4," + R + "," + ARC + "," + THETA + ","
                + PRESSURE + "," + AXIAL_DIV + "," + CIRC_DIV + "," + THICK_DIV
                + "," + radialMm + "," + magnitudeMm + "," + totalElements + ","
                + theta0Count + "," + axialEdgeCount + "," + radialEdgeCount + ","
                + outerCount + "," + innerCount + ",completed");
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void createBoxSelection(Model model, String tag, int dim,
            double xmin, double xmax, double ymin, double ymax, double zmin, double zmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(dim));
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", Double.toString(xmin));
        model.component("comp1").selection(tag).set("xmax", Double.toString(xmax));
        model.component("comp1").selection(tag).set("ymin", Double.toString(ymin));
        model.component("comp1").selection(tag).set("ymax", Double.toString(ymax));
        model.component("comp1").selection(tag).set("zmin", Double.toString(zmin));
        model.component("comp1").selection(tag).set("zmax", Double.toString(zmax));
    }

    private static void createCylinderSelection(Model model, String tag, int dim,
            double rin, double rout, double eps) {
        model.component("comp1").selection().create(tag, "Cylinder");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(dim));
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("axistype", "x");
        model.component("comp1").selection(tag).set("pos", new String[] {"0", "0", "0"});
        model.component("comp1").selection(tag).set("rin", Double.toString(rin));
        model.component("comp1").selection(tag).set("r", Double.toString(rout));
        model.component("comp1").selection(tag).set("bottom", Double.toString(-eps));
        model.component("comp1").selection(tag).set("top", Double.toString(L + eps));
        // The annular radius gate already isolates the cylindrical face.
        // Keep the angular gate full because COMSOL chooses an axis-dependent
        // zero direction for component Cylinder selections.
        model.component("comp1").selection(tag).set("angle1", "0");
        model.component("comp1").selection(tag).set("angle2", "360");
    }

    private static void createUnionSelection(Model model, String tag, int dim, String[] inputs) {
        model.component("comp1").selection().create(tag, "Union");
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(dim));
        model.component("comp1").selection(tag).set("input", inputs);
    }

    private static String baseName() {
        return "comsol_curved_" + RUN_TAG.replaceAll("[^A-Za-z0-9_\\-]+", "_");
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
