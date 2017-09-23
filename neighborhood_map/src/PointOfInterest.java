/**
 * Created by local_admin on 9/23/2017.
 */
public class PointOfInterest implements Comparable<PointOfInterest> {
    public final String data_type;
    public final String common_name;
    public final String address;
    public final double latitude;
    public final double longitude;

    public PointOfInterest(String data_type, String common_name, String address, double latitude, double longitude) {
        this.data_type = data_type;
        this.common_name = common_name;
        this.latitude = latitude;
        this.address = address;
        this.longitude = longitude;
    }

    public PointOfInterest(String values) {
        String[] split = values.split("\t");
        int i = 0;
        data_type = split[i++];
        common_name = split[i++];
        address = split[i++];
        String website = split[i++];
        latitude = Double.parseDouble(split[i++]);
        longitude = Double.parseDouble(split[i++]);
      }


    @Override
    public int compareTo(PointOfInterest o) {
        int ret = data_type.compareTo(o.data_type);
        if(ret != 0)
            return ret;
        ret = common_name.compareTo(o.common_name);
        if(ret != 0)
            return ret;
        return 0;
    }
}
