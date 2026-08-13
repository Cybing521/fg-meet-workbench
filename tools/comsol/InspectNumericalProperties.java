import com.comsol.model.Model;
import com.comsol.model.NumericalFeature;
import com.comsol.model.util.ModelUtil;
import java.util.Arrays;

public class InspectNumericalProperties {
    public static void main(String[] args) throws Exception {
        String path = System.getenv("FG_COMSOL_INSPECT_MPH");
        if (path == null || path.trim().isEmpty()) {
            throw new IllegalArgumentException("FG_COMSOL_INSPECT_MPH is required");
        }
        Model model = ModelUtil.load("InspectModel", path);
        NumericalFeature feature = model.result().numerical("interp1");
        for (String property : feature.properties()) {
            String[] allowed = feature.getAllowedPropertyValues(property);
            if (property.toLowerCase().contains("frame") || property.toLowerCase().contains("coord")) {
                System.out.println("NUMERICAL_PROPERTY," + property + ",allowed," + Arrays.toString(allowed)
                    + ",value," + feature.getString(property));
            }
        }
        for (String property : model.result().dataset("dset1").properties()) {
            String[] allowed = model.result().dataset("dset1").getAllowedPropertyValues(property);
            if (property.toLowerCase().contains("frame") || property.toLowerCase().contains("coord")) {
                System.out.println("DATASET_PROPERTY," + property + ",allowed," + Arrays.toString(allowed)
                    + ",value," + model.result().dataset("dset1").getString(property));
            }
        }
    }
}
