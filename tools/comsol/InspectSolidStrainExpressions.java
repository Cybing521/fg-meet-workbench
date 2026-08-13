import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/** Read-only expression probe against a completed local COMSOL model. */
public class InspectSolidStrainExpressions {
    public static Model run() throws Exception {
        String path = "G:/fg-meet-workbench/outputs/paper-20260715-fgmee/experiments/comsol/"
            + "comsol_direct_magnetic_200A_20x20x10_Model.mph";
        System.out.println("STRAIN_MODEL_PATH," + path);
        Model model;
        try {
            model = ModelUtil.load("StrainProbe", path);
        } catch (Exception ex) {
            System.out.println("STRAIN_MODEL_LOAD_FAIL," + ex.toString());
            ex.printStackTrace(System.out);
            throw ex;
        }
        String[] expressions = new String[] {
            "solid.eXX", "solid.eYY", "solid.eZZ",
            "solid.ex", "solid.ey", "solid.ez",
            "solid.el11", "solid.el22", "solid.el33",
            "ux", "vy", "wz"
        };
        int counter = 0;
        for (String expression : expressions) {
            String tag = "p" + (++counter);
            try {
                model.result().numerical().create(tag, "Interp");
                model.result().numerical(tag).set("expr", new String[] {expression});
                model.result().numerical(tag).set("coord", new double[][] {{0.15}, {0.15}, {0.0027}});
                double[][] values = model.result().numerical(tag).getReal();
                System.out.println("STRAIN_EXPR_OK," + expression + "," + values[0][0]);
            } catch (Exception ex) {
                System.out.println("STRAIN_EXPR_FAIL," + expression + "," + ex.getMessage());
            }
        }
        return model;
    }

    public static void main(String[] args) throws Exception {
        run();
    }
}
