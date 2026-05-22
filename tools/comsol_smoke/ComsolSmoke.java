import com.comsol.model.Model;
import com.comsol.model.util.ModelUtil;

public class ComsolSmoke {
    public static Model run() {
        Model model = ModelUtil.create("Model");
        model.label("comsol_smoke.mph");
        model.param().set("a", "1[m]");
        return model;
    }

    public static void main(String[] args) {
        run();
    }
}
