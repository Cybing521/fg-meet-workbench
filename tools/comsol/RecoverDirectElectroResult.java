import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/** Recover postprocessing from a solved model whose original interface point was ambiguous. */
public class RecoverDirectElectroResult {
    private static int numericalCounter = 0;

    public static void main(String[] args) throws Exception {
        String inputMph = requiredEnv("FG_RECOVER_INPUT_MPH");
        String outputDir = requiredEnv("FG_DIRECT_OUTPUT_DIR");
        String runTag = env("FG_DIRECT_RUN_TAG", "direct_electro_recovered");
        double voltage = Double.parseDouble(env("FG_DIRECT_VOLTAGE", "300"));
        new File(outputDir).mkdirs();

        Model model = ModelUtil.load("RecoveredDirectElectro", inputMph);

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

        File csv = new File(outputDir, "comsol_" + runTag + "_summary.csv");
        writeSummaryCsv(csv, voltage, wCenterMm, wFreeMidMm, matlabReferenceMm,
            qianReferenceMm, relativeErrorMatlabPct, relativeErrorQianPct,
            vBottomOuter, vBottomInner, vTopInner, vTopOuter, ezBottom, ezTop);

        File cleanMph = new File(outputDir, "comsol_" + runTag + ".mph");
        model.save(cleanMph.getAbsolutePath());

        System.out.println("RECOVER_DIRECT_ELECTRO_RESULT,w_center_mm," + wCenterMm
            + ",w_free_mid_mm," + wFreeMidMm
            + ",matlab_reference_mm," + matlabReferenceMm
            + ",relative_error_matlab_pct," + relativeErrorMatlabPct
            + ",qian_reference_mm," + qianReferenceMm
            + ",relative_error_qian_pct," + relativeErrorQianPct
            + ",V_bottom_outer," + vBottomOuter + ",V_bottom_inner," + vBottomInner
            + ",V_top_inner," + vTopInner + ",V_top_outer," + vTopOuter
            + ",Ez_bottom_Vpm," + ezBottom + ",Ez_top_Vpm," + ezTop
            + ",summary_csv," + csv.getAbsolutePath());
    }

    private static double interpolateScalar(Model model, String expression, double x, double y, double z) {
        String tag = "recoverInterp" + (++numericalCounter);
        model.result().numerical().create(tag, "Interp");
        model.result().numerical(tag).set("expr", new String[] {expression});
        model.result().numerical(tag).set("coord", new double[][] {{x}, {y}, {z}});
        double[][] values = model.result().numerical(tag).getReal();
        if (values.length >= 1 && values[0].length >= 1) {
            return values[0][0];
        }
        throw new IllegalStateException("Unexpected interpolation shape for " + expression);
    }

    private static void writeSummaryCsv(File path, double voltage, double wCenterMm,
            double wFreeMidMm, double matlabReferenceMm, double qianReferenceMm,
            double relativeErrorMatlabPct, double relativeErrorQianPct,
            double vBottomOuter, double vBottomInner, double vTopInner, double vTopOuter,
            double ezBottom, double ezTop) {
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(new FileWriter(path));
            writer.println("case_id,voltage_layer_V,w_center_mm,w_free_mid_mm,matlab_reference_mm,qian_reference_mm,relative_error_matlab_pct,relative_error_qian_pct,V_bottom_outer,V_bottom_inner,V_top_inner,V_top_outer,Ez_bottom_Vpm,Ez_top_Vpm,status");
            writer.println("direct_electro_CFFF_U_Vf06_recovered," + voltage + ","
                + wCenterMm + "," + wFreeMidMm + "," + matlabReferenceMm + ","
                + qianReferenceMm + "," + relativeErrorMatlabPct + ","
                + relativeErrorQianPct + "," + vBottomOuter + "," + vBottomInner
                + "," + vTopInner + "," + vTopOuter + "," + ezBottom + ","
                + ezTop + ",completed_from_saved_converged_solution");
        } catch (IOException ex) {
            throw new RuntimeException("Failed to write recovered direct electro summary: " + path, ex);
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private static double relativeErrorPct(double value, double reference) {
        return 100.0 * Math.abs(value - reference) / Math.abs(reference);
    }

    private static String env(String name, String defaultValue) {
        String value = System.getenv(name);
        return value == null || value.trim().length() == 0 ? defaultValue : value.trim();
    }

    private static String requiredEnv(String name) {
        String value = env(name, "");
        if (value.length() == 0) {
            throw new IllegalArgumentException(name + " is required");
        }
        return value;
    }
}
