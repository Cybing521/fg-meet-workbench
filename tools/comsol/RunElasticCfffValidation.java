import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

public class RunElasticCfffValidation {
    private static final double L = 0.3;
    private static final double W = 0.3;
    private static final double H = 0.006;
    private static final int NLAYER = 10;

    private static final double E = 1.206e11;
    private static final double NU = 0.3398;
    private static final double RHO = 5600.0;

    private static final int MESH_SIZE = intEnv("FG_COMSOL_MESH_SIZE", 5);
    private static final int SWEEP_LAYERS = intEnv("FG_COMSOL_SWEEP_LAYERS", NLAYER);
    private static final String MESH_MODE = env("FG_COMSOL_MESH_MODE", "auto").toLowerCase();
    private static final String LOAD_MODE = env("FG_COMSOL_LOAD_MODE", "pressure").toLowerCase();
    private static final String RUN_TAG = env("FG_COMSOL_RUN_TAG", "");
    private static final boolean LAYERED_GEOMETRY = boolEnv("FG_COMSOL_LAYERED", false);
    private static final String LAYER_CSV = env("FG_COMSOL_LAYER_CSV",
        "G:\\fg-meet-workbench\\comsol\\export\\Thermal_CFFF_U_Vf0.6-30x30-10layer_layers.csv");

    private static final double[][] POINTS = new double[][] {
        {0.050, 0.050, 0.0},
        {0.100, 0.050, 0.0},
        {0.150, 0.050, 0.0},
        {0.200, 0.050, 0.0},
        {0.250, 0.050, 0.0},
        {0.050, 0.150, 0.0},
        {0.100, 0.150, 0.0},
        {0.150, 0.150, 0.0},
        {0.200, 0.150, 0.0},
        {0.250, 0.150, 0.0},
        {0.050, 0.250, 0.0},
        {0.100, 0.250, 0.0},
        {0.150, 0.250, 0.0},
        {0.200, 0.250, 0.0},
        {0.250, 0.250, 0.0}
    };

    public static Model run() {
        double[][] layers = readLayers();
        Model model = ModelUtil.create("Model");
        model.modelPath("G:\\fg-meet-workbench\\output");
        model.label(modelLabel());

        model.param().set("L", "0.3[m]");
        model.param().set("W", "0.3[m]");
        model.param().set("H", "0.006[m]");
        model.param().set("p0", "15000[Pa]");

        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").lengthUnit("m");

        if (LAYERED_GEOMETRY) {
            for (int i = 0; i < layers.length; i++) {
                String tag = "blk" + (i + 1);
                model.component("comp1").geom("geom1").create(tag, "Block");
                model.component("comp1").geom("geom1").feature(tag).set("base", "corner");
                model.component("comp1").geom("geom1").feature(tag).set("size", new String[] {
                    Double.toString(L), Double.toString(W), Double.toString(layerZ2(layers[i]) - layerZ1(layers[i]))
                });
                model.component("comp1").geom("geom1").feature(tag).set("pos", new String[] {
                    "0", "0", Double.toString(layerZ1(layers[i]))
                });
            }
        } else {
            model.component("comp1").geom("geom1").create("blk1", "Block");
            model.component("comp1").geom("geom1").feature("blk1").set("base", "corner");
            model.component("comp1").geom("geom1").feature("blk1").set("size", new String[] {
                Double.toString(L), Double.toString(W), Double.toString(H)
            });
            model.component("comp1").geom("geom1").feature("blk1").set("pos", new String[] {
                "0", "0", Double.toString(-H / 2.0)
            });
        }
        model.component("comp1").geom("geom1").run();

        model.component("comp1").selection().create("sel_fixed", "Box");
        model.component("comp1").selection("sel_fixed").label("CFFF fixed edge x=0");
        model.component("comp1").selection("sel_fixed").set("entitydim", "2");
        model.component("comp1").selection("sel_fixed").set("condition", "allvertices");
        model.component("comp1").selection("sel_fixed").set("xmin", "-1e-9");
        model.component("comp1").selection("sel_fixed").set("xmax", "1e-9");
        model.component("comp1").selection("sel_fixed").set("ymin", "-1e-9");
        model.component("comp1").selection("sel_fixed").set("ymax", "0.300000001");
        model.component("comp1").selection("sel_fixed").set("zmin", "-0.003000001");
        model.component("comp1").selection("sel_fixed").set("zmax", "0.003000001");

        model.component("comp1").selection().create("sel_top", "Box");
        model.component("comp1").selection("sel_top").label("Top pressure face");
        model.component("comp1").selection("sel_top").set("entitydim", "2");
        model.component("comp1").selection("sel_top").set("condition", "allvertices");
        model.component("comp1").selection("sel_top").set("xmin", "-1e-9");
        model.component("comp1").selection("sel_top").set("xmax", "0.300000001");
        model.component("comp1").selection("sel_top").set("ymin", "-1e-9");
        model.component("comp1").selection("sel_top").set("ymax", "0.300000001");
        model.component("comp1").selection("sel_top").set("zmin", "0.002999999");
        model.component("comp1").selection("sel_top").set("zmax", "0.003000001");

        int fixedBoundaryCount = model.component("comp1").selection("sel_fixed").entities(2).length;
        int topBoundaryCount = model.component("comp1").selection("sel_top").entities(2).length;
        System.out.println("SELECTION_COUNTS,fixed_boundary_count," + fixedBoundaryCount
            + ",top_boundary_count," + topBoundaryCount);
        System.out.println("RUN_CONFIG,run_tag," + displayRunTag()
            + ",mesh_mode," + MESH_MODE + ",mesh_size," + MESH_SIZE
            + ",sweep_layers," + SWEEP_LAYERS + ",load_mode," + LOAD_MODE
            + ",layered_geometry," + LAYERED_GEOMETRY + ",layer_csv," + LAYER_CSV);

        if (LAYERED_GEOMETRY) {
            createLayerMaterials(model, layers);
        } else {
            model.component("comp1").material().create("mat1", "Common");
            model.component("comp1").material("mat1").label("U Vf0.6 equivalent homogeneous solid");
            model.component("comp1").material("mat1").propertyGroup("def").set("youngsmodulus", Double.toString(E) + "[Pa]");
            model.component("comp1").material("mat1").propertyGroup("def").set("poissonsratio", Double.toString(NU));
            model.component("comp1").material("mat1").propertyGroup("def").set("density", Double.toString(RHO) + "[kg/m^3]");
        }

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1").selection().named("sel_fixed");
        model.component("comp1").physics("solid").create("bndl1", "BoundaryLoad", 2);
        model.component("comp1").physics("solid").feature("bndl1").selection().named("sel_top");
        if ("forcearea".equals(LOAD_MODE)) {
            model.component("comp1").physics("solid").feature("bndl1").set("LoadType", "ForceArea");
            model.component("comp1").physics("solid").feature("bndl1")
                .set("FperArea", new String[] {"0", "0", "-15000[N/m^2]"});
        } else if ("pressure".equals(LOAD_MODE)) {
            model.component("comp1").physics("solid").feature("bndl1").set("LoadType", "FollowerPressure");
            model.component("comp1").physics("solid").feature("bndl1")
                .set("FollowerPressure", "15000[N/m^2]");
        } else {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_LOAD_MODE: " + LOAD_MODE
                + " (use pressure or forcearea)");
        }

        model.component("comp1").mesh().create("mesh1");
        if ("sweep".equals(MESH_MODE)) {
            model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
            model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
            model.component("comp1").mesh("mesh1").feature("swe1").set("sweeppath", "straight");
            model.component("comp1").mesh("mesh1").feature("swe1").create("size1", "Size");
            model.component("comp1").mesh("mesh1").feature("swe1").feature("size1").set("hauto", MESH_SIZE);
            model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
            model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1").set("numelem", SWEEP_LAYERS);
        } else if ("auto".equals(MESH_MODE)) {
            model.component("comp1").mesh("mesh1").autoMeshSize(MESH_SIZE);
        } else {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_MESH_MODE: " + MESH_MODE
                + " (use auto or sweep)");
        }
        model.component("comp1").mesh("mesh1").run();

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").run();

        double[][] coord = new double[3][POINTS.length];
        for (int i = 0; i < POINTS.length; i++) {
            coord[0][i] = POINTS[i][0];
            coord[1][i] = POINTS[i][1];
            coord[2][i] = POINTS[i][2];
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
            System.out.println("U_Vf06_elastic,U,0.6,elastic,CFFF,p" + (i + 1) + ","
                + POINTS[i][0] + "," + POINTS[i][1] + "," + POINTS[i][2] + ","
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
                writer.println("U_Vf06_elastic,U,0.6,elastic,CFFF,p" + (i + 1) + ","
                    + POINTS[i][0] + "," + POINTS[i][1] + "," + POINTS[i][2] + ","
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

    private static boolean boolEnv(String name, boolean defaultValue) {
        String value = env(name, "");
        if (value.length() == 0) {
            return defaultValue;
        }
        return "1".equals(value) || "true".equalsIgnoreCase(value)
            || "yes".equalsIgnoreCase(value) || "on".equalsIgnoreCase(value);
    }

    private static String displayRunTag() {
        if (RUN_TAG.length() == 0) {
            return "default";
        }
        return RUN_TAG;
    }

    private static String baseName() {
        if (RUN_TAG.length() == 0) {
            return "comsol_elastic_cfff_U_Vf06";
        }
        return "comsol_elastic_cfff_U_Vf06_" + RUN_TAG;
    }

    private static String modelLabel() {
        return baseName() + ".mph";
    }

    private static String csvPath() {
        return "G:\\fg-meet-workbench\\output\\" + baseName() + "_points.csv";
    }

    private static void createLayerMaterials(Model model, double[][] layers) {
        for (int i = 0; i < layers.length; i++) {
            double[] layer = layers[i];
            int layerId = layerId(layer);
            String selectionTag = "sel_layer_" + layerId;
            model.component("comp1").selection().create(selectionTag, "Box");
            model.component("comp1").selection(selectionTag).label("Layer " + layerId + " domain");
            model.component("comp1").selection(selectionTag).set("entitydim", "3");
            model.component("comp1").selection(selectionTag).set("condition", "allvertices");
            model.component("comp1").selection(selectionTag).set("xmin", "-1e-9");
            model.component("comp1").selection(selectionTag).set("xmax", "0.300000001");
            model.component("comp1").selection(selectionTag).set("ymin", "-1e-9");
            model.component("comp1").selection(selectionTag).set("ymax", "0.300000001");
            model.component("comp1").selection(selectionTag).set("zmin", Double.toString(layerZ1(layer) - 1e-10));
            model.component("comp1").selection(selectionTag).set("zmax", Double.toString(layerZ2(layer) + 1e-10));

            int domainCount = model.component("comp1").selection(selectionTag).entities(3).length;
            System.out.println("LAYER_SELECTION,layer," + layerId + ",domain_count," + domainCount
                + ",z1," + layerZ1(layer) + ",z2," + layerZ2(layer));

            String matTag = "mat" + layerId;
            model.component("comp1").material().create(matTag, "Common");
            model.component("comp1").material(matTag).label("Layer " + layerId + " from CSV");
            model.component("comp1").material(matTag).selection().named(selectionTag);
            model.component("comp1").material(matTag).propertyGroup("def")
                .set("youngsmodulus", Double.toString(layerE1(layer)) + "[Pa]");
            model.component("comp1").material(matTag).propertyGroup("def")
                .set("poissonsratio", Double.toString(layerNu12(layer)));
            model.component("comp1").material(matTag).propertyGroup("def")
                .set("density", Double.toString(layerDensity(layer)) + "[kg/m^3]");
        }
    }

    private static double[][] readLayers() {
        if (!LAYERED_GEOMETRY) {
            return new double[0][0];
        }
        double[][] layers = new double[NLAYER][6];
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new FileReader(LAYER_CSV));
            String line = reader.readLine();
            int index = 0;
            while ((line = reader.readLine()) != null) {
                if (line.trim().length() == 0) {
                    continue;
                }
                String[] parts = line.split(",");
                if (parts.length < 27) {
                    throw new IOException("Bad layer CSV row: " + line);
                }
                layers[index][0] = Double.parseDouble(parts[0].trim());
                layers[index][1] = Double.parseDouble(parts[1].trim());
                layers[index][2] = Double.parseDouble(parts[3].trim());
                layers[index][3] = Double.parseDouble(parts[23].trim());
                layers[index][4] = Double.parseDouble(parts[24].trim());
                layers[index][5] = Double.parseDouble(parts[25].trim());
                index++;
            }
            if (index != NLAYER) {
                throw new IOException("Expected " + NLAYER + " layers but read " + index + " from " + LAYER_CSV);
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to read COMSOL layer CSV: " + LAYER_CSV, ex);
        } finally {
            if (reader != null) {
                try {
                    reader.close();
                } catch (IOException ex) {
                    throw new RuntimeException("Failed to close COMSOL layer CSV: " + LAYER_CSV, ex);
                }
            }
        }
        return layers;
    }

    private static int layerId(double[] layer) {
        return (int) Math.round(layer[0]);
    }

    private static double layerE1(double[] layer) {
        return layer[1];
    }

    private static double layerNu12(double[] layer) {
        return layer[2];
    }

    private static double layerDensity(double[] layer) {
        return layer[3];
    }

    private static double layerZ1(double[] layer) {
        return layer[4];
    }

    private static double layerZ2(double[] layer) {
        return layer[5];
    }

    public static void main(String[] args) {
        run();
    }
}
