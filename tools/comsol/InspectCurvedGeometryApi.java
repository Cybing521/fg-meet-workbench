import java.util.Arrays;

import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

/** One-shot API inventory for a work-plane rectangle revolved into a sector. */
public class InspectCurvedGeometryApi {
    public static void main(String[] args) {
        Model model = ModelUtil.create("InspectCurvedGeometryApi");
        model.component().create("comp1", true);
        model.component("comp1").geom().create("geom1", 3);
        model.component("comp1").geom("geom1").create("wp1", "WorkPlane");
        model.component("comp1").geom("geom1").feature("wp1").geom()
            .create("r1", "Rectangle");
        model.component("comp1").geom("geom1").create("rev1", "Revolve");

        printFeature("workplane", model, "wp1");
        printWorkPlaneFeature("rectangle", model, "wp1", "r1");
        printFeature("revolve", model, "rev1");
        model.component("comp1").selection().create("cyl1", "Cylinder");
        printSelection("cylinder_selection", model, "cyl1");
    }

    private static void printSelection(String label, Model model, String tag) {
        System.out.println("FEATURE_BEGIN," + label);
        for (String property : model.component("comp1").selection(tag).properties()) {
            String value;
            try {
                value = Arrays.deepToString(model.component("comp1").selection(tag)
                    .getStringMatrix(property));
            } catch (Exception ex1) {
                try {
                    value = Arrays.toString(model.component("comp1").selection(tag)
                        .getStringArray(property));
                } catch (Exception ex2) {
                    try {
                        value = model.component("comp1").selection(tag).getString(property);
                    } catch (Exception ex3) {
                        value = "<unreadable>";
                    }
                }
            }
            String[] allowed = model.component("comp1").selection(tag)
                .getAllowedPropertyValues(property);
            System.out.println("PROPERTY," + label + "," + property + ",value," + value
                + ",allowed," + Arrays.toString(allowed));
        }
        System.out.println("FEATURE_END," + label);
    }

    private static void printFeature(String label, Model model, String tag) {
        System.out.println("FEATURE_BEGIN," + label);
        for (String property : model.component("comp1").geom("geom1").feature(tag).properties()) {
            String value;
            try {
                value = Arrays.deepToString(model.component("comp1").geom("geom1")
                    .feature(tag).getStringMatrix(property));
            } catch (Exception ex1) {
                try {
                    value = Arrays.toString(model.component("comp1").geom("geom1")
                        .feature(tag).getStringArray(property));
                } catch (Exception ex2) {
                    try {
                        value = model.component("comp1").geom("geom1")
                            .feature(tag).getString(property);
                    } catch (Exception ex3) {
                        value = "<unreadable>";
                    }
                }
            }
            String[] allowed = model.component("comp1").geom("geom1").feature(tag)
                .getAllowedPropertyValues(property);
            System.out.println("PROPERTY," + label + "," + property + ",value," + value
                + ",allowed," + Arrays.toString(allowed));
        }
        System.out.println("FEATURE_END," + label);
    }

    private static void printWorkPlaneFeature(String label, Model model, String workPlane, String tag) {
        System.out.println("FEATURE_BEGIN," + label);
        for (String property : model.component("comp1").geom("geom1").feature(workPlane)
                .geom().feature(tag).properties()) {
            String value;
            try {
                value = Arrays.deepToString(model.component("comp1").geom("geom1")
                    .feature(workPlane).geom().feature(tag).getStringMatrix(property));
            } catch (Exception ex1) {
                try {
                    value = Arrays.toString(model.component("comp1").geom("geom1")
                        .feature(workPlane).geom().feature(tag).getStringArray(property));
                } catch (Exception ex2) {
                    try {
                        value = model.component("comp1").geom("geom1").feature(workPlane)
                            .geom().feature(tag).getString(property);
                    } catch (Exception ex3) {
                        value = "<unreadable>";
                    }
                }
            }
            String[] allowed = model.component("comp1").geom("geom1").feature(workPlane)
                .geom().feature(tag).getAllowedPropertyValues(property);
            System.out.println("PROPERTY," + label + "," + property + ",value," + value
                + ",allowed," + Arrays.toString(allowed));
        }
        System.out.println("FEATURE_END," + label);
    }
}
