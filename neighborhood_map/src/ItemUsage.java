/**
 * Created by local_admin on 9/23/2017.
 */
public class ItemUsage {
    public final String name;
    public final boolean used;

    public ItemUsage(String name, boolean used) {
        this.name = name;
        this.used = used;
    }
    public ItemUsage(String values) {
        String[] split = values.split("\t");
        name = split[0];
        this.used = "used".equals(split[1]);
    }
}
