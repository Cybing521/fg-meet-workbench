import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

public class RunElasticPlateValidation {
    private static final double L = 0.3;
    private static final double W = 0.3;
    private static final double H = 0.006;

    private static final String CASE_ID = env("FG_COMSOL_CASE_ID", "U_Vf06_elastic");
    private static final String FG_MODE = env("FG_COMSOL_FG_MODE", "U");
    private static final String VF0 = env("FG_COMSOL_VF0", "0.6");
    private static final String BC = env("FG_COMSOL_BC", "CFFF").toUpperCase();
    private static final String RUN_TAG = env("FG_COMSOL_RUN_TAG", "plate_U_Vf06_CFFF");
    private static final int MESH_SIZE = intEnv("FG_COMSOL_MESH_SIZE", 3);

    private static final double[][] POINTS = new double[][] {
        {0.050, 0.050},
        {0.100, 0.050},
        {0.150, 0.050},
        {0.200, 0.050},
        {0.250, 0.050},
        {0.050, 0.150},
        {0.100, 0.150},
        {0.150, 0.150},
        {0.200, 0.150},
        {0.250, 0.150},
        {0.050, 0.250},
        {0.100, 0.250},
        {0.150, 0.250},
        {0.200, 0.250},
        {0.250, 0.250}
    };

    public static Model run() {
        Model model = ModelUtil.create("Model");
        model.modelPath("G:\\fg-meet-workbench\\output");
        model.label(modelLabel());

        model.param().set("L", "0.3[m]");
        model.param().set("W", "0.3[m]");
        model.param().set("H", "0.006[m]");
        model.param().set("p0", "15000[Pa]");

        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 2);
        model.component("comp1").geom("geom1").lengthUnit("m");
        model.component("comp1").geom("geom1").create("r1", "Rectangle");
        model.component("comp1").geom("geom1").feature("r1").set("base", "corner");
        model.component("comp1").geom("geom1").feature("r1").set("size", new String[] {
            Double.toString(L), Double.toString(W)
        });
        model.component("comp1").geom("geom1").run();

        createEdgeSelection(model, "sel_fixed_x0", "Fixed edge x=0", "-1e-9", "1e-9");
        if ("CFCF".equals(BC)) {
            createEdgeSelection(model, "sel_fixed_xL", "Fixed edge x=L", "0.299999999", "0.300000001");
        } else if (!"CFFF".equals(BC)) {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_BC: " + BC + " (use CFFF or CFCF)");
        }

        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("U Vf0.6 equivalent plate material");
        model.component("comp1").material("mat1").propertyGroup("def").set("youngsmodulus", "1.206e11[Pa]");
        model.component("comp1").material("mat1").propertyGroup("def").set("poissonsratio", "0.3398");
        model.component("comp1").material("mat1").propertyGroup("def").set("density", "5600[kg/m^3]");

        model.component("comp1").physics().create("plate", "Plate", "geom1");
        model.component("comp1").physics("plate").feature("to1").set("d", "0.006[m]");

        model.component("comp1").physics("plate").create("fix1", "Fixed", 1);
        model.component("comp1").physics("plate").feature("fix1").selection().named("sel_fixed_x0");
        if ("CFCF".equals(BC)) {
            model.component("comp1").physics("plate").create("fix2", "Fixed", 1);
            model.component("comp1").physics("plate").feature("fix2").selection().named("sel_fixed_xL");
        }

        model.component("comp1").physics("plate").create("fl1", "FaceLoad", 2);
        model.component("comp1").physics("plate").feature("fl1").selection().all();
        model.component("comp1").physics("plate").feature("fl1").set("Ff", new String[] {"0", "0", "-15000[N/m^2]"});

        int fixedEdgeCount = model.component("comp1").selection("sel_fixed_x0").entities(1).length;
        if ("CFCF".equals(BC)) {
            fixedEdgeCount += model.component("comp1").selection("sel_fixed_xL").entities(1).length;
        }
        System.out.println("SELECTION_COUNTS,fixed_edge_count," + fixedEdgeCount + ",loaded_domains,all");
        System.out.println("RUN_CONFIG,run_tag," + RUN_TAG
            + ",physics,Plate,mesh_size," + MESH_SIZE
            + ",thickness," + H
            + ",load,-15000[N/m^2]"
            + ",case_id," + CASE_ID
            + ",bc," + BC);

        model.component("comp1").mesh().create("mesh1");
        model.component("comp1").mesh("mesh1").autoMeshSize(MESH_SIZE);
        model.component("comp1").mesh("mesh1").run();

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").run();

        double[][] coord = new double[2][POINTS.length];
        for (int i = 0; i < POINTS.length; i++) {
            coord[0][i] = POINTS[i][0];
            coord[1][i] = POINTS[i][1];
        }
        model.result().numerical().create("interp1", "Interp");
        model.result().numerical("interp1").set("expr", new String[] {"w"});
        model.result().numerical("interp1").set("coord", coord);
        double[][] values = model.result().numerical("interp1").getReal();

        System.out.println("VALIDATION_BEGIN");
        System.out.println("case_id,fg_mode,vf0,load_case,bc,point_id,x_m,y_m,z_m,comsol_w_m,comsol_w_mm");
        writeCsvHeaderAndRows(values);
        for (int i = 0; i < POINTS.length; i++) {
            double w = valueAtPoint(values, i);
            System.out.println(CASE_ID + "," + FG_MODE + "," + VF0 + ",elastic," + BC + ",p" + (i + 1) + ","
                + POINTS[i][0] + "," + POINTS[i][1] + ",0.0,"
                + w + "," + (1000.0 * w));
        }
        System.out.println("VALIDATION_END");

        return model;
    }

    private static double valueAtPoint(double[][] values, int pointIndex) {
        if (values.length == POINTS.length && values[pointIndex].length > 0) {
            return values[pointIndex][0];
        }
        if (values.length > 0 && values[0].length == POINTS.length) {
            return values[0][pointIndex];
        }
        throw new IllegalStateException("Unexpected interpolation result shape: "
            + values.length + "x" + (values.length == 0 ? 0 : values[0].length));
    }

    private static void writeCsvHeaderAndRows(double[][] values) {
        String path = csvPath();
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,fg_mode,vf0,load_case,bc,point_id,x_m,y_m,z_m,comsol_w_m,comsol_w_mm");
            for (int i = 0; i < POINTS.length; i++) {
                double w = valueAtPoint(values, i);
                writer.println(CASE_ID + "," + FG_MODE + "," + VF0 + ",elastic," + BC + ",p" + (i + 1) + ","
                    + POINTS[i][0] + "," + POINTS[i][1] + ",0.0,"
                    + w + "," + (1000.0 * w));
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write COMSOL validation CSV: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void createEdgeSelection(Model model, String tag, String label, String xmin, String xmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).label(label);
        model.component("comp1").selection(tag).set("entitydim", "1");
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", xmin);
        model.component("comp1").selection(tag).set("xmax", xmax);
        model.component("comp1").selection(tag).set("ymin", "-1e-9");
        model.component("comp1").selection(tag).set("ymax", "0.300000001");
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
        if (value.length() == 0) {
            return defaultValue;
        }
        return Integer.parseInt(value);
    }

    private static String modelLabel() {
        return baseName() + ".mph";
    }

    private static String baseName() {
        return "comsol_elastic_plate_validation_" + safeName(RUN_TAG);
    }

    private static String csvPath() {
        return "G:\\fg-meet-workbench\\output\\" + baseName() + "_points.csv";
    }

    private static String safeName(String value) {
        return value.replaceAll("[^A-Za-z0-9_\\-]+", "_");
    }

    public static void main(String[] args) {
        run();
    }
}
