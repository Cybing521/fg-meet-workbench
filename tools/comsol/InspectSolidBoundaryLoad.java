import java.util.Arrays;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

public class InspectSolidBoundaryLoad {
    public static Model run() {
        Model model = ModelUtil.create("Model");
        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").create("blk1", "Block");
        model.component("comp1").geom("geom1").feature("blk1").set("size", new String[] {"1", "1", "0.1"});
        model.component("comp1").geom("geom1").run();
        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").create("bndl1", "BoundaryLoad", 2);

        System.out.println("INSPECT_BOUNDARY_LOAD_BEGIN");
        for (String property : model.component("comp1").physics("solid").feature("bndl1").properties()) {
            String[] allowed = model.component("comp1").physics("solid").feature("bndl1")
                .getAllowedPropertyValues(property);
            System.out.println(property + "=" + (allowed == null ? "" : Arrays.toString(allowed)));
        }
        System.out.println("INSPECT_BOUNDARY_LOAD_END");
        return model;
    }

    public static void main(String[] args) {
        run();
    }
}
