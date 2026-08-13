import java.util.Arrays;

import com.comsol.model.Model;
import com.comsol.model.ModelEntity;
import com.comsol.model.util.ModelUtil;
import com.comsol.model.physics.PhysicsFeature;

/** Read-only API inventory used before constructing the direct magnetic model. */
public class InspectDirectMagneticApi {
    public static void main(String[] args) {
        Model model = ModelUtil.create("InspectDirectMagneticApi");
        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").create("blk1", "Block");
        model.component("comp1").geom("geom1").run();

        model.component("comp1").physics().create(
            "wm", "WeakFormPDE", "geom1", new String[] {"Vm"}
        );
        printEntity("physics_wm", model.component("comp1").physics("wm"));
        for (String tag : model.component("comp1").physics("wm").feature().tags()) {
            printFeature("wm_" + tag, model.component("comp1").physics("wm").feature(tag));
        }
        model.component("comp1").physics("wm").create("dir1", "DirichletBoundary", 2);
        printFeature("wm_dir1", model.component("comp1").physics("wm").feature("dir1"));

        model.component("comp1").physics().create("solid", "SolidMechanics", "geom1");
        model.component("comp1").physics("solid").feature("lemm1")
            .create("exs1", "ExternalStress", 3);
        printFeature("solid_lemm1_exs1",
            model.component("comp1").physics("solid").feature("lemm1").feature("exs1"));
    }

    private static void printEntity(String label, ModelEntity entity) {
        System.out.println("ENTITY," + label + ",tag," + entity.tag());
    }

    private static void printFeature(String label, PhysicsFeature feature) {
        System.out.println("FEATURE," + label + ",tag," + feature.tag());
        for (String property : feature.properties()) {
            String value;
            try {
                value = Arrays.deepToString(feature.getStringMatrix(property));
            } catch (Exception matrixEx) {
                try {
                    value = Arrays.toString(feature.getStringArray(property));
                } catch (Exception arrayEx) {
                    try {
                        value = feature.getString(property);
                    } catch (Exception stringEx) {
                        value = "<unreadable:" + stringEx.getClass().getSimpleName() + ">";
                    }
                }
            }
            String[] allowed = feature.getAllowedPropertyValues(property);
            System.out.println("PROPERTY," + label + "," + property
                + ",value," + value + ",allowed," + Arrays.toString(allowed));
        }
    }
}
