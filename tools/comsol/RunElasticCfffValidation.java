import java.io.BufferedReader;
import java.io.File;
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
    private static final int INPLANE_DIVISIONS = intEnv("FG_COMSOL_INPLANE_DIVISIONS", 0);
    private static final String MESH_MODE = env("FG_COMSOL_MESH_MODE", "auto").toLowerCase();
    private static final String LOAD_MODE = env("FG_COMSOL_LOAD_MODE", "pressure").toLowerCase();
    private static final String RUN_TAG = env("FG_COMSOL_RUN_TAG", "");
    private static final boolean LAYERED_GEOMETRY = boolEnv("FG_COMSOL_LAYERED", false);
    private static final String SOLID_MODEL = env("FG_COMSOL_SOLID_MODEL", "isotropic").toLowerCase();
    private static final String DISPLACEMENT_ORDER = env("FG_COMSOL_DISPLACEMENT_ORDER", "2s").toLowerCase();
    private static final boolean GEOMETRIC_NONLINEAR = boolEnv("FG_COMSOL_GEOMETRIC_NONLINEAR", false);
    private static final String OUTPUT_DIR = env("FG_COMSOL_OUTPUT_DIR", defaultOutputDir());
    private static final String LAYER_CSV = env("FG_COMSOL_LAYER_CSV", defaultLayerCsv());
    private static final String CASE_ID = env("FG_COMSOL_CASE_ID", "U_Vf06_elastic");
    private static final String FG_MODE = env("FG_COMSOL_FG_MODE", "U");
    private static final String VF0 = env("FG_COMSOL_VF0", "0.6");
    private static final String BC = env("FG_COMSOL_BC", "CFFF").toUpperCase();
    private static final double STIFFNESS_SCALE = doubleEnv("FG_COMSOL_STIFFNESS_SCALE", 1.0);

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
        {0.250, 0.250, 0.0},
        {0.300, 0.150, 0.0}
    };

    public static Model run() {
        double[][] layers = readLayers();
        if (!isSupportedSolidModel()) {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_SOLID_MODEL: " + SOLID_MODEL
                + " (use isotropic, orthotropic, qian_mee, or qian_thermal_piezo)");
        }
        if (usesOrthotropicSolid() && !LAYERED_GEOMETRY) {
            throw new IllegalArgumentException("FG_COMSOL_SOLID_MODEL=orthotropic requires FG_COMSOL_LAYERED=true");
        }
        new File(OUTPUT_DIR).mkdirs();
        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
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

        createFixedEdgeSelection(model, "sel_fixed_x0", "Fixed edge x=0", "-1e-9", "1e-9");
        if ("CFCF".equals(BC)) {
            createFixedEdgeSelection(model, "sel_fixed_xL", "Fixed edge x=L", "0.299999999", "0.300000001");
        } else if (!"CFFF".equals(BC)) {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_BC: " + BC + " (use CFFF or CFCF)");
        }

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

        if ((INPLANE_DIVISIONS > 0 && "sweep".equals(MESH_MODE)) || usesQianThermalPiezo()) {
            createBoxSelection(model, "sel_mesh_bottom_face", "Mapped mesh source face", 2,
                "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        }
        if (INPLANE_DIVISIONS > 0 && "sweep".equals(MESH_MODE)) {
            createBoxSelection(model, "sel_mesh_bottom_edges", "Mapped mesh source edges", 1,
                "-1e-9", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002999999");
        }

        int fixedBoundaryCount = model.component("comp1").selection("sel_fixed_x0").entities(2).length;
        if ("CFCF".equals(BC)) {
            fixedBoundaryCount += model.component("comp1").selection("sel_fixed_xL").entities(2).length;
        }
        int topBoundaryCount = model.component("comp1").selection("sel_top").entities(2).length;
        System.out.println("SELECTION_COUNTS,fixed_boundary_count," + fixedBoundaryCount
            + ",top_boundary_count," + topBoundaryCount);
        System.out.println("RUN_CONFIG,run_tag," + displayRunTag()
            + ",mesh_mode," + MESH_MODE + ",mesh_size," + MESH_SIZE
            + ",inplane_divisions," + INPLANE_DIVISIONS
            + ",sweep_layers," + SWEEP_LAYERS + ",load_mode," + LOAD_MODE
            + ",layered_geometry," + LAYERED_GEOMETRY + ",solid_model," + SOLID_MODEL
            + ",displacement_order," + DISPLACEMENT_ORDER
            + ",geometric_nonlinear," + GEOMETRIC_NONLINEAR
            + ",stiffness_scale," + STIFFNESS_SCALE
            + ",layer_csv," + LAYER_CSV
            + ",case_id," + CASE_ID + ",bc," + BC);

        if (usesQianThermalPiezo()) {
            createQianThermalPiezoMaterial(model);
        } else if (LAYERED_GEOMETRY) {
            createLayerMaterials(model, layers);
        } else {
            model.component("comp1").material().create("mat1", "Common");
            model.component("comp1").material("mat1").label("U Vf0.6 equivalent homogeneous solid");
            model.component("comp1").material("mat1").propertyGroup("def")
                .set("youngsmodulus", Double.toString(scaleStiffness(E)) + "[Pa]");
            model.component("comp1").material("mat1").propertyGroup("def").set("poissonsratio", Double.toString(NU));
            model.component("comp1").material("mat1").propertyGroup("def").set("density", Double.toString(RHO) + "[kg/m^3]");
        }

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").prop("ShapeProperty")
            .set("order_displacement", DISPLACEMENT_ORDER);
        if (usesQianThermalPiezo()) {
            model.component("comp1").physics("solid").create("pzm1", "PiezoelectricMaterialModel");
            model.component("comp1").physics("solid").feature("pzm1").selection().all();
            model.component("comp1").physics().create("es", "Electrostatics", "geom1");
            model.component("comp1").physics("es").create("ccnp1", "ChargeConservationPiezo");
            model.component("comp1").physics("es").feature("ccnp1").selection().all();
            model.component("comp1").physics("es").create("gnd1", "Ground", 2);
            model.component("comp1").physics("es").feature("gnd1").selection().named("sel_top");
            model.component("comp1").physics("es").create("gnd2", "Ground", 2);
            model.component("comp1").physics("es").feature("gnd2").selection().named("sel_mesh_bottom_face");
            model.component("comp1").multiphysics().create("pze1", "PiezoelectricEffect", 3);
            model.component("comp1").multiphysics("pze1").set("Solid_physics", "solid");
            model.component("comp1").multiphysics("pze1").set("Electrostatics_physics", "es");
        } else if (usesOrthotropicSolid()) {
            model.component("comp1").physics("solid").feature("lemm1").set("SolidModel", "Orthotropic");
            model.component("comp1").physics("solid").feature("lemm1").set("OrthotropicOption", "OrthotropicStd");
        }
        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1").selection().named("sel_fixed_x0");
        if ("CFCF".equals(BC)) {
            model.component("comp1").physics("solid").create("fix2", "Fixed", 2);
            model.component("comp1").physics("solid").feature("fix2").selection().named("sel_fixed_xL");
        }
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
            if (INPLANE_DIVISIONS > 0) {
                model.component("comp1").mesh("mesh1").create("map1", "Map");
                model.component("comp1").mesh("mesh1").feature("map1").selection()
                    .named("sel_mesh_bottom_face");
                model.component("comp1").mesh("mesh1").feature("map1").create("dis1", "Distribution");
                model.component("comp1").mesh("mesh1").feature("map1").feature("dis1").selection()
                    .named("sel_mesh_bottom_edges");
                model.component("comp1").mesh("mesh1").feature("map1").feature("dis1")
                    .set("numelem", INPLANE_DIVISIONS);
            }
            model.component("comp1").mesh("mesh1").create("swe1", "Sweep");
            model.component("comp1").mesh("mesh1").feature("swe1").set("facemethod", "quad");
            model.component("comp1").mesh("mesh1").feature("swe1").set("sweeppath", "straight");
            model.component("comp1").mesh("mesh1").feature("swe1").create("size1", "Size");
            if (INPLANE_DIVISIONS > 0) {
                model.component("comp1").mesh("mesh1").feature("swe1").selection("sourceface")
                    .named("sel_mesh_bottom_face");
            } else {
                model.component("comp1").mesh("mesh1").feature("swe1").feature("size1").set("hauto", MESH_SIZE);
            }
            model.component("comp1").mesh("mesh1").feature("swe1").create("dis1", "Distribution");
            model.component("comp1").mesh("mesh1").feature("swe1").feature("dis1").set("numelem", SWEEP_LAYERS);
        } else if ("auto".equals(MESH_MODE)) {
            model.component("comp1").mesh("mesh1").autoMeshSize(MESH_SIZE);
        } else {
            throw new IllegalArgumentException("Unsupported FG_COMSOL_MESH_MODE: " + MESH_MODE
                + " (use auto or sweep)");
        }
        model.component("comp1").mesh("mesh1").run();
        System.out.println("MESH_STATS,total_elements," + model.component("comp1").mesh("mesh1").getNumElem());

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        if (usesQianThermalPiezo()) {
            model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
            model.study("std1").feature("stat").setSolveFor("/physics/es", true);
            model.study("std1").feature("stat").setSolveFor("/multiphysics/pze1", true);
        }
        if (GEOMETRIC_NONLINEAR) {
            model.study("std1").feature("stat").set("geometricNonlinearity", "on");
        }
        model.study("std1").run();
        if (GEOMETRIC_NONLINEAR) {
            model.result().dataset("dset1").set("frametype", "material");
        }

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
            System.out.println(CASE_ID + "," + FG_MODE + "," + VF0 + ",elastic," + BC + ",p" + (i + 1) + ","
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
                writer.println(CASE_ID + "," + FG_MODE + "," + VF0 + ",elastic," + BC + ",p" + (i + 1) + ","
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

    private static double doubleEnv(String name, double defaultValue) {
        String value = env(name, "");
        if (value.length() == 0) {
            return defaultValue;
        }
        return Double.parseDouble(value);
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
            return "comsol_elastic_validation_" + safeName(CASE_ID);
        }
        return "comsol_elastic_validation_" + safeName(RUN_TAG);
    }

    private static String modelLabel() {
        return baseName() + ".mph";
    }

    private static String csvPath() {
        return new File(OUTPUT_DIR, baseName() + "_points.csv").getPath();
    }

    private static String defaultOutputDir() {
        return new File("output").getAbsolutePath();
    }

    private static String defaultLayerCsv() {
        return new File("comsol\\export\\Thermal_CFFF_U_Vf0.6-30x30-10layer_layers.csv").getPath();
    }

    private static void createFixedEdgeSelection(Model model, String tag, String label, String xmin, String xmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).label(label);
        model.component("comp1").selection(tag).set("entitydim", "2");
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", xmin);
        model.component("comp1").selection(tag).set("xmax", xmax);
        model.component("comp1").selection(tag).set("ymin", "-1e-9");
        model.component("comp1").selection(tag).set("ymax", "0.300000001");
        model.component("comp1").selection(tag).set("zmin", "-0.003000001");
        model.component("comp1").selection(tag).set("zmax", "0.003000001");
    }

    private static void createBoxSelection(Model model, String tag, String label, int entityDim,
            String xmin, String xmax, String ymin, String ymax, String zmin, String zmax) {
        model.component("comp1").selection().create(tag, "Box");
        model.component("comp1").selection(tag).label(label);
        model.component("comp1").selection(tag).set("entitydim", Integer.toString(entityDim));
        model.component("comp1").selection(tag).set("condition", "allvertices");
        model.component("comp1").selection(tag).set("xmin", xmin);
        model.component("comp1").selection(tag).set("xmax", xmax);
        model.component("comp1").selection(tag).set("ymin", ymin);
        model.component("comp1").selection(tag).set("ymax", ymax);
        model.component("comp1").selection(tag).set("zmin", zmin);
        model.component("comp1").selection(tag).set("zmax", zmax);
    }

    private static String safeName(String value) {
        return value.replaceAll("[^A-Za-z0-9_\\-]+", "_");
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
            assignLayerMaterial(model, matTag, layer);
        }
    }

    private static void createQianThermalPiezoMaterial(Model model) {
        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("Qian Table 1 thermal-piezo analogy material");
        model.component("comp1").material("mat1").selection().all();
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("density", "5600[kg/m^3]");
        model.component("comp1").material("mat1").propertyGroup()
            .create("StressCharge", "Stress-charge form");
        model.component("comp1").material("mat1").propertyGroup("StressCharge")
            .set("cE", new String[] {
                stiffnessText(200e9), stiffnessText(110e9), stiffnessText(110e9), "0[Pa]", "0[Pa]", "0[Pa]",
                stiffnessText(110e9), stiffnessText(200e9), stiffnessText(110e9), "0[Pa]", "0[Pa]", "0[Pa]",
                stiffnessText(110e9), stiffnessText(110e9), stiffnessText(190e9), "0[Pa]", "0[Pa]", "0[Pa]",
                "0[Pa]", "0[Pa]", "0[Pa]", stiffnessText(45e9), "0[Pa]", "0[Pa]",
                "0[Pa]", "0[Pa]", "0[Pa]", "0[Pa]", stiffnessText(45e9), "0[Pa]",
                "0[Pa]", "0[Pa]", "0[Pa]", "0[Pa]", "0[Pa]", stiffnessText(45e9)
            });
        model.component("comp1").material("mat1").propertyGroup("StressCharge")
            .set("eES", new String[] {
                "0[C/m^2]", "0[C/m^2]", "4857000[C/m^2]",
                "0[C/m^2]", "0[C/m^2]", "4857000[C/m^2]",
                "0[C/m^2]", "0[C/m^2]", "4320000[C/m^2]",
                "0[C/m^2]", "0[C/m^2]", "0[C/m^2]",
                "0[C/m^2]", "0[C/m^2]", "0[C/m^2]",
                "0[C/m^2]", "0[C/m^2]", "0[C/m^2]"
            });
        model.component("comp1").material("mat1").propertyGroup("StressCharge")
            .set("epsilonrS", new String[] {
                "0", "0", "0",
                "0", "0", "0",
                "0", "0", "3.693e13"
            });
    }

    private static void assignLayerMaterial(Model model, String matTag, double[] layer) {
        model.component("comp1").material(matTag).propertyGroup("def")
            .set("density", Double.toString(layerDensity(layer)) + "[kg/m^3]");
        if (usesOrthotropicSolid()) {
            model.component("comp1").material(matTag).propertyGroup().create("Orthotropic", "Orthotropic");
            double e1 = layerE1(layer);
            double e2 = layerE2(layer);
            double e3 = layerE2(layer);
            double nu12 = layerNu12(layer);
            double nu13 = layerNu12(layer);
            double nu23 = layerNu23(layer);
            if ("qian_mee".equals(SOLID_MODEL)) {
                // Engineering constants obtained by inverting Qian Shenyun Table 1's
                // MEE stiffness matrix: C11=C22=200, C12=C13=C23=110,
                // C33=190, C44=C55=C66=45 GPa.
                e1 = 120.57915057915058e9;
                e2 = 120.57915057915058e9;
                e3 = 111.93548387096773e9;
                nu12 = 0.33976833976833987;
                nu13 = 0.38223938223938225;
                nu23 = 0.38223938223938225;
            }
            model.component("comp1").material(matTag).propertyGroup("Orthotropic")
                .set("Evector", new String[] {
                    Double.toString(scaleStiffness(e1)) + "[Pa]",
                    Double.toString(scaleStiffness(e2)) + "[Pa]",
                    Double.toString(scaleStiffness(e3)) + "[Pa]"
                });
            model.component("comp1").material(matTag).propertyGroup("Orthotropic")
                .set("nuvector", new String[] {
                    Double.toString(nu12),
                    Double.toString(nu13),
                    Double.toString(nu23)
                });
            model.component("comp1").material(matTag).propertyGroup("Orthotropic")
                .set("Gvector", new String[] {
                    Double.toString(scaleStiffness(layerG12(layer))) + "[Pa]",
                    Double.toString(scaleStiffness(layerG13(layer))) + "[Pa]",
                    Double.toString(scaleStiffness(layerG23(layer))) + "[Pa]"
                });
        } else {
            model.component("comp1").material(matTag).propertyGroup("def")
                .set("youngsmodulus", Double.toString(scaleStiffness(layerE1(layer))) + "[Pa]");
            model.component("comp1").material(matTag).propertyGroup("def")
                .set("poissonsratio", Double.toString(layerNu12(layer)));
        }
    }

    private static double[][] readLayers() {
        if (!LAYERED_GEOMETRY) {
            return new double[0][0];
        }
        double[][] layers = new double[NLAYER][11];
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
                if (parts.length < 26) {
                    throw new IOException("Bad layer CSV row: " + line);
                }
                layers[index][0] = Double.parseDouble(parts[0].trim());
                layers[index][1] = Double.parseDouble(parts[1].trim());
                layers[index][2] = Double.parseDouble(parts[2].trim());
                layers[index][3] = Double.parseDouble(parts[3].trim());
                layers[index][4] = Double.parseDouble(parts[4].trim());
                layers[index][5] = Double.parseDouble(parts[5].trim());
                layers[index][6] = Double.parseDouble(parts[6].trim());
                layers[index][7] = Double.parseDouble(parts[7].trim());
                layers[index][8] = Double.parseDouble(parts[23].trim());
                layers[index][9] = Double.parseDouble(parts[24].trim());
                layers[index][10] = Double.parseDouble(parts[25].trim());
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

    private static double layerE2(double[] layer) {
        return layer[2];
    }

    private static double layerNu12(double[] layer) {
        return layer[3];
    }

    private static double layerNu23(double[] layer) {
        return layer[4];
    }

    private static double layerG12(double[] layer) {
        return layer[5];
    }

    private static double layerG13(double[] layer) {
        return layer[6];
    }

    private static double layerG23(double[] layer) {
        return layer[7];
    }

    private static double layerDensity(double[] layer) {
        return layer[8];
    }

    private static double scaleStiffness(double value) {
        return value * STIFFNESS_SCALE;
    }

    private static String stiffnessText(double value) {
        return Double.toString(scaleStiffness(value)) + "[Pa]";
    }

    private static double layerZ1(double[] layer) {
        return layer[9];
    }

    private static double layerZ2(double[] layer) {
        return layer[10];
    }

    private static boolean usesOrthotropicSolid() {
        return "orthotropic".equals(SOLID_MODEL) || "qian_mee".equals(SOLID_MODEL);
    }

    private static boolean usesQianThermalPiezo() {
        return "qian_thermal_piezo".equals(SOLID_MODEL);
    }

    private static boolean isSupportedSolidModel() {
        return "isotropic".equals(SOLID_MODEL) || usesOrthotropicSolid() || usesQianThermalPiezo();
    }

    public static void main(String[] args) {
        run();
    }
}
