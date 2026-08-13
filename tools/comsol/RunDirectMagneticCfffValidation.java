import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/**
 * Independent 3D COMSOL validation for the CFFF magnetic-actuation case.
 *
 * <p>The magnetic scalar potential is solved as a normalized Laplace field in
 * the two disconnected outer MEE layers.  Multiplication by {@code Mamp}
 * recovers the physical magnetic scalar potential in ampere.  The resulting
 * H_z=-d(Vm)/dz is coupled into the structural constitutive equation through
 * the case-file piezomagnetic stress coefficients q31 and q32.  No equivalent
 * surface pressure is prescribed.</p>
 */
public class RunDirectMagneticCfffValidation {
    private static final double L = 0.300;
    private static final double W = 0.300;
    private static final double H = 0.006;
    private static final double HLAYER = 0.0006;
    private static final int NLAYER = 10;

    private static final double YOUNG = 1.206e11;
    private static final double NU = 0.3398;
    private static final double RHO = 5600.0;
    private static final double Q31 = 49.47;
    private static final double Q32 = 49.47;

    private static final double MAGNETIC_POTENTIAL = doubleEnv("FG_DIRECT_MAGNETIC_POTENTIAL_A", 200.0);
    private static final int INPLANE_DIVISIONS = intEnv("FG_DIRECT_INPLANE_DIVISIONS", 15);
    private static final int THROUGH_THICKNESS_DIVISIONS = intEnv("FG_DIRECT_THICKNESS_DIVISIONS", 10);
    private static final String MATERIAL_MODEL = env(
        "FG_DIRECT_MATERIAL_MODEL", "isotropic_reduced"
    ).toLowerCase();
    private static final String COUPLING_MODE = env(
        "FG_DIRECT_COUPLING_MODE", "volume_external_stress"
    ).toLowerCase();
    private static final String OUTPUT_DIR = env(
        "FG_DIRECT_OUTPUT_DIR",
        new File("outputs/paper-20260715-fgmee/experiments/comsol").getAbsolutePath()
    );
    private static final String RUN_TAG = env("FG_DIRECT_RUN_TAG", "direct_magnetic_200A");

    private static int numericalCounter = 0;

    public static Model run() {
        new File(OUTPUT_DIR).mkdirs();
        validateConfiguration();

        Model model = ModelUtil.create("Model");
        model.modelPath(OUTPUT_DIR);
        model.label(baseName() + ".mph");

        model.param().set("L", "0.3[m]");
        model.param().set("W", "0.3[m]");
        model.param().set("H", "0.006[m]");
        model.param().set("hlay", "0.0006[m]");
        model.param().set("Mamp", Double.toString(MAGNETIC_POTENTIAL) + "[A]");
        model.param().set("q31", Double.toString(Q31) + "[N/(A*m)]");
        model.param().set("q32", Double.toString(Q32) + "[N/(A*m)]");

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
        createUnionSelection(model, "sel_outer_potential", 2, new String[] {
            "sel_bottom_outer", "sel_top_outer"
        });
        createUnionSelection(model, "sel_inner_potential", 2, new String[] {
            "sel_bottom_inner", "sel_top_inner"
        });
        createOuterLayerSideSelections(model);

        int fixedCount = model.component("comp1").selection("sel_fixed").entities(2).length;
        int bottomDomainCount = model.component("comp1").selection("sel_bottom_dom").entities(3).length;
        int topDomainCount = model.component("comp1").selection("sel_top_dom").entities(3).length;
        int outerDomainCount = model.component("comp1").selection("sel_outer_dom").entities(3).length;
        int outerPotentialCount = model.component("comp1").selection("sel_outer_potential").entities(2).length;
        int innerPotentialCount = model.component("comp1").selection("sel_inner_potential").entities(2).length;
        System.out.println("DIRECT_MAGNETIC_SELECTIONS,fixed," + fixedCount
            + ",bottom_domain," + bottomDomainCount
            + ",top_domain," + topDomainCount
            + ",outer_domains," + outerDomainCount
            + ",outer_potential_faces," + outerPotentialCount
            + ",inner_potential_faces," + innerPotentialCount);
        if (fixedCount == 0 || bottomDomainCount != 1 || topDomainCount != 1
                || outerDomainCount != 2 || outerPotentialCount != 2 || innerPotentialCount != 2) {
            throw new IllegalStateException("Unexpected geometry selection counts; direct magnetic model is not safe to solve");
        }

        createMaterial(model);

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").prop("ShapeProperty").set("order_displacement", "2s");
        if (!"isotropic_reduced".equals(MATERIAL_MODEL)) {
            model.component("comp1").physics("solid").feature("lemm1")
                .set("SolidModel", "Orthotropic");
            model.component("comp1").physics("solid").feature("lemm1")
                .set("OrthotropicOption", "OrthotropicStd");
        }
        model.component("comp1").physics("solid").create("fix1", "Fixed", 2);
        model.component("comp1").physics("solid").feature("fix1").selection().named("sel_fixed");

        if ("volume_external_stress".equals(COUPLING_MODE)) {
            model.component("comp1").physics("solid").feature("lemm1")
                .create("exs1", "ExternalStress", 3);
            model.component("comp1").physics("solid").feature("lemm1").feature("exs1")
                .selection().named("sel_outer_dom");
            model.component("comp1").physics("solid").feature("lemm1").feature("exs1")
                .set("StressInputType", "StressTensorMaterial");
            model.component("comp1").physics("solid").feature("lemm1").feature("exs1")
                .set("ContributionType", "Stress");
            model.component("comp1").physics("solid").feature("lemm1").feature("exs1")
                .set("Sext", new String[] {
                    "sigma_m_xx", "0", "0",
                    "0", "sigma_m_yy", "0",
                    "0", "0", "0"
                });
        } else {
            // Qian's COMSOL comparison first converts the magnetic potential
            // into an equivalent in-plane stress and then loads the four side
            // faces of each active outer layer.  COMSOL's follower-pressure
            // sign for this feature/selection combination was verified by a
            // signed diagnostic run: the bottom active layer requires the
            // negative expression and the top layer the positive expression
            // to match the direct constitutive-stress deflection direction.
            model.component("comp1").physics("solid").create("bndl_bottom", "BoundaryLoad", 2);
            model.component("comp1").physics("solid").feature("bndl_bottom")
                .selection().named("sel_bottom_sides");
            model.component("comp1").physics("solid").feature("bndl_bottom")
                .set("LoadType", "FollowerPressure");
            model.component("comp1").physics("solid").feature("bndl_bottom")
                .set("FollowerPressure", "-q31*Mamp/hlay");
            model.component("comp1").physics("solid").create("bndl_top", "BoundaryLoad", 2);
            model.component("comp1").physics("solid").feature("bndl_top")
                .selection().named("sel_top_sides");
            model.component("comp1").physics("solid").feature("bndl_top")
                .set("LoadType", "FollowerPressure");
            model.component("comp1").physics("solid").feature("bndl_top")
                .set("FollowerPressure", "q31*Mamp/hlay");
        }

        model.component("comp1").physics().create(
            "wm", "WeakFormPDE", "geom1", new String[] {"psiM"}
        );
        model.component("comp1").physics("wm").selection().named("sel_outer_dom");
        model.component("comp1").physics("wm").feature("wfeq1").set(
            "weak", new String[] {
                "-(test(psiMx)*psiMx+test(psiMy)*psiMy+test(psiMz)*psiMz)"
            }
        );
        model.component("comp1").physics("wm").create("dir_inner", "DirichletBoundary", 2);
        model.component("comp1").physics("wm").feature("dir_inner")
            .selection().named("sel_inner_potential");
        model.component("comp1").physics("wm").feature("dir_inner").set("r", new String[] {"0"});
        model.component("comp1").physics("wm").create("dir_outer", "DirichletBoundary", 2);
        model.component("comp1").physics("wm").feature("dir_outer")
            .selection().named("sel_outer_potential");
        model.component("comp1").physics("wm").feature("dir_outer").set("r", new String[] {"1"});

        model.component("comp1").variable().create("var1");
        model.component("comp1").variable("var1").selection().named("sel_outer_dom");
        model.component("comp1").variable("var1").set("Vm_direct", "Mamp*psiM");
        model.component("comp1").variable("var1").set("Hz_direct", "-Mamp*psiMz");
        model.component("comp1").variable("var1").set("sigma_m_xx", "-q31*Hz_direct");
        model.component("comp1").variable("var1").set("sigma_m_yy", "-q32*Hz_direct");

        createSweptMesh(model);

        model.study().create("std1");
        model.study("std1").create("stat", "Stationary");
        model.study("std1").feature("stat").setSolveFor("/physics/solid", true);
        model.study("std1").feature("stat").setSolveFor("/physics/wm", true);

        System.out.println("DIRECT_MAGNETIC_CONFIG,magnetic_potential_A," + MAGNETIC_POTENTIAL
            + ",inplane_divisions," + INPLANE_DIVISIONS
            + ",through_thickness_divisions," + THROUGH_THICKNESS_DIVISIONS
            + ",material_model," + MATERIAL_MODEL
            + ",coupling_mode," + COUPLING_MODE
            + ",q31_N_per_A_m," + Q31 + ",q32_N_per_A_m," + Q32
            + ",coupling,scalar_potential_gradient_to_external_constitutive_stress");
        model.study("std1").run();

        double wCenterM = interpolateScalar(model, "w", 0.15, 0.15, 0.0);
        double wFreeMidM = interpolateScalar(model, "w", 0.30 - 1e-9, 0.15, 0.0);
        double vmBottomOuter = interpolateScalar(model, "Vm_direct", 0.15, 0.15, -0.003 + 1e-9);
        double vmBottomInner = interpolateScalar(model, "Vm_direct", 0.15, 0.15, -0.0024 - 1e-9);
        double vmTopInner = interpolateScalar(model, "Vm_direct", 0.15, 0.15, 0.0024 + 1e-9);
        double vmTopOuter = interpolateScalar(model, "Vm_direct", 0.15, 0.15, 0.003 - 1e-9);
        double hzBottom = interpolateScalar(model, "Hz_direct", 0.15, 0.15, -0.0027);
        double hzTop = interpolateScalar(model, "Hz_direct", 0.15, 0.15, 0.0027);
        double stressBottom = interpolateScalar(model, "sigma_m_xx", 0.15, 0.15, -0.0027);
        double stressTop = interpolateScalar(model, "sigma_m_xx", 0.15, 0.15, 0.0027);

        double wCenterMm = 1000.0 * wCenterM;
        double wFreeMidMm = 1000.0 * wFreeMidM;
        double matlabReferenceMm = 0.1745857472;
        double qianPresentReferenceMm = 0.175;
        double qianComsolReferenceMm = 0.173;
        double relativeErrorMatlabPct = relativeErrorPct(wCenterMm, matlabReferenceMm);
        double relativeErrorQianPresentPct = relativeErrorPct(wCenterMm, qianPresentReferenceMm);
        double relativeErrorQianComsolPct = relativeErrorPct(wCenterMm, qianComsolReferenceMm);

        writeSummaryCsv(wCenterMm, wFreeMidMm, matlabReferenceMm,
            qianPresentReferenceMm, qianComsolReferenceMm,
            relativeErrorMatlabPct, relativeErrorQianPresentPct, relativeErrorQianComsolPct,
            vmBottomOuter, vmBottomInner, vmTopInner, vmTopOuter,
            hzBottom, hzTop, stressBottom, stressTop);
        writeCenterlineCsv(model);

        System.out.println("DIRECT_MAGNETIC_RESULT,w_center_mm," + wCenterMm
            + ",w_free_mid_mm," + wFreeMidMm
            + ",matlab_reference_mm," + matlabReferenceMm
            + ",relative_error_matlab_pct," + relativeErrorMatlabPct
            + ",qian_present_reference_mm," + qianPresentReferenceMm
            + ",relative_error_qian_present_pct," + relativeErrorQianPresentPct
            + ",qian_comsol_reference_mm," + qianComsolReferenceMm
            + ",relative_error_qian_comsol_pct," + relativeErrorQianComsolPct
            + ",Hz_bottom_Apm," + hzBottom + ",Hz_top_Apm," + hzTop
            + ",stress_bottom_Pa," + stressBottom + ",stress_top_Pa," + stressTop);

        return model;
    }

    private static void createMaterial(Model model) {
        model.component("comp1").material().create("mat1", "Common");
        model.component("comp1").material("mat1").label("Qian U Vf0.6 diagnostic material: " + MATERIAL_MODEL);
        model.component("comp1").material("mat1").selection().all();
        model.component("comp1").material("mat1").propertyGroup("def")
            .set("density", Double.toString(RHO) + "[kg/m^3]");
        if ("isotropic_reduced".equals(MATERIAL_MODEL)) {
            model.component("comp1").material("mat1").propertyGroup("def")
                .set("youngsmodulus", Double.toString(YOUNG) + "[Pa]");
            model.component("comp1").material("mat1").propertyGroup("def")
                .set("poissonsratio", Double.toString(NU));
            return;
        }

        double e1 = YOUNG;
        double e2 = YOUNG;
        double e3 = YOUNG;
        double nu12 = NU;
        double nu13 = 0.0;
        double nu23 = 0.0;
        if ("qian_full_orthotropic".equals(MATERIAL_MODEL)) {
            // Engineering constants obtained by inverting Qian's reported
            // 6x6 MEE stiffness tensor (GPa): C11=C22=200, C33=190,
            // C12=C13=C23=110, C44=C55=C66=45.
            e1 = 120.57915057915058e9;
            e2 = 120.57915057915058e9;
            e3 = 111.93548387096773e9;
            nu12 = 0.33976833976833987;
            nu13 = 0.38223938223938225;
            nu23 = 0.38223938223938225;
        }
        model.component("comp1").material("mat1").propertyGroup()
            .create("Orthotropic", "Orthotropic");
        model.component("comp1").material("mat1").propertyGroup("Orthotropic")
            .set("Evector", new String[] {
                Double.toString(e1) + "[Pa]",
                Double.toString(e2) + "[Pa]",
                Double.toString(e3) + "[Pa]"
            });
        model.component("comp1").material("mat1").propertyGroup("Orthotropic")
            .set("nuvector", new String[] {
                Double.toString(nu12), Double.toString(nu13), Double.toString(nu23)
            });
        model.component("comp1").material("mat1").propertyGroup("Orthotropic")
            .set("Gvector", new String[] {
                "4.5e10[Pa]", "4.5e10[Pa]", "4.5e10[Pa]"
            });
    }

    private static void createOuterLayerSideSelections(Model model) {
        createBoxSelection(model, "sel_bottom_x0", 2,
            "-1e-9", "1e-9", "-1e-9", "0.300000001", "-0.003000001", "-0.002399999");
        createBoxSelection(model, "sel_bottom_xL", 2,
            "0.299999999", "0.300000001", "-1e-9", "0.300000001", "-0.003000001", "-0.002399999");
        createBoxSelection(model, "sel_bottom_y0", 2,
            "-1e-9", "0.300000001", "-1e-9", "1e-9", "-0.003000001", "-0.002399999");
        createBoxSelection(model, "sel_bottom_yW", 2,
            "-1e-9", "0.300000001", "0.299999999", "0.300000001", "-0.003000001", "-0.002399999");
        createUnionSelection(model, "sel_bottom_sides", 2, new String[] {
            "sel_bottom_x0", "sel_bottom_xL", "sel_bottom_y0", "sel_bottom_yW"
        });
        createBoxSelection(model, "sel_top_x0", 2,
            "-1e-9", "1e-9", "-1e-9", "0.300000001", "0.002399999", "0.003000001");
        createBoxSelection(model, "sel_top_xL", 2,
            "0.299999999", "0.300000001", "-1e-9", "0.300000001", "0.002399999", "0.003000001");
        createBoxSelection(model, "sel_top_y0", 2,
            "-1e-9", "0.300000001", "-1e-9", "1e-9", "0.002399999", "0.003000001");
        createBoxSelection(model, "sel_top_yW", 2,
            "-1e-9", "0.300000001", "0.299999999", "0.300000001", "0.002399999", "0.003000001");
        createUnionSelection(model, "sel_top_sides", 2, new String[] {
            "sel_top_x0", "sel_top_xL", "sel_top_y0", "sel_top_yW"
        });
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
        System.out.println("DIRECT_MAGNETIC_MESH,total_elements,"
            + model.component("comp1").mesh("mesh1").getNumElem());
    }

    private static double interpolateScalar(Model model, String expression, double x, double y, double z) {
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

    private static void writeSummaryCsv(double wCenterMm, double wFreeMidMm,
            double matlabReferenceMm, double qianPresentReferenceMm, double qianComsolReferenceMm,
            double relativeErrorMatlabPct, double relativeErrorQianPresentPct,
            double relativeErrorQianComsolPct,
            double vmBottomOuter, double vmBottomInner, double vmTopInner, double vmTopOuter,
            double hzBottom, double hzTop, double stressBottom, double stressTop) {
        File path = new File(OUTPUT_DIR, baseName() + "_summary.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,material_model,coupling_mode,inplane_divisions,thickness_divisions_per_layer,magnetic_potential_layer_A,w_center_mm,w_free_mid_mm,matlab_reference_mm,qian_present_reference_mm,qian_comsol_reference_mm,relative_error_matlab_pct,relative_error_qian_present_pct,relative_error_qian_comsol_pct,Vm_bottom_outer_A,Vm_bottom_inner_A,Vm_top_inner_A,Vm_top_outer_A,Hz_bottom_Apm,Hz_top_Apm,sigma_bottom_Pa,sigma_top_Pa,status");
            writer.println("direct_magnetic_CFFF_U_Vf06," + MATERIAL_MODEL + "," + COUPLING_MODE
                + "," + INPLANE_DIVISIONS + "," + THROUGH_THICKNESS_DIVISIONS + "," + MAGNETIC_POTENTIAL + ","
                + wCenterMm + "," + wFreeMidMm + "," + matlabReferenceMm + ","
                + qianPresentReferenceMm + "," + qianComsolReferenceMm + ","
                + relativeErrorMatlabPct + "," + relativeErrorQianPresentPct + ","
                + relativeErrorQianComsolPct + "," + vmBottomOuter + "," + vmBottomInner
                + "," + vmTopInner + "," + vmTopOuter + "," + hzBottom + "," + hzTop
                + "," + stressBottom + "," + stressTop + ",completed");
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write direct magnetic summary: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static void writeCenterlineCsv(Model model) {
        double[] qianPresent = new double[] {
            0.0, 0.00550, 0.0243, 0.0584, 0.109, 0.175,
            0.256, 0.353, 0.465, 0.591, 0.732
        };
        double[] qianComsol = new double[] {
            0.0, 0.00532, 0.0239, 0.0578, 0.108, 0.173,
            0.255, 0.351, 0.463, 0.589, 0.729
        };
        File path = new File(OUTPUT_DIR, baseName() + "_centerline.csv");
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("x_over_a,x_m,y_m,z_m,comsol_w_mm,qian_present_w_mm,qian_comsol_w_mm,delta_vs_qian_present_mm");
            for (int i = 0; i <= 10; i++) {
                double x = 0.03 * i;
                double sampleX = i == 10 ? x - 1e-9 : x;
                double wMm = 1000.0 * interpolateScalar(model, "w", sampleX, 0.15, 0.0);
                writer.println((i / 10.0) + "," + x + ",0.15,0," + wMm + ","
                    + qianPresent[i] + "," + qianComsol[i] + "," + (wMm - qianPresent[i]));
            }
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write magnetic centerline CSV: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
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

    private static void validateConfiguration() {
        if (!"isotropic_reduced".equals(MATERIAL_MODEL)
                && !"case_orthotropic".equals(MATERIAL_MODEL)
                && !"qian_full_orthotropic".equals(MATERIAL_MODEL)) {
            throw new IllegalArgumentException("Unsupported FG_DIRECT_MATERIAL_MODEL: " + MATERIAL_MODEL
                + " (use isotropic_reduced, case_orthotropic, or qian_full_orthotropic)");
        }
        if (!"volume_external_stress".equals(COUPLING_MODE)
                && !"equivalent_side_pressure".equals(COUPLING_MODE)) {
            throw new IllegalArgumentException("Unsupported FG_DIRECT_COUPLING_MODE: " + COUPLING_MODE
                + " (use volume_external_stress or equivalent_side_pressure)");
        }
        if (INPLANE_DIVISIONS < 1 || THROUGH_THICKNESS_DIVISIONS < 1) {
            throw new IllegalArgumentException("Mesh division counts must be positive");
        }
    }

    public static void main(String[] args) {
        run();
    }
}
