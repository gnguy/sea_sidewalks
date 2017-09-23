import java.io.*;
import java.util.*;

/**
 * Created by local_admin on 9/23/2017.
 */
public class TypeFilter {

    public static List<PointOfInterest> readPointsOfInterest(File f) {
        List<PointOfInterest> ret = new ArrayList<>();
        try {
            LineNumberReader rdr = new LineNumberReader(new FileReader(f));
            String s = rdr.readLine(); // ignore columns
            s = rdr.readLine();
            while(s != null) {
                ret.add(new PointOfInterest(s));
                s = rdr.readLine();
            }
            rdr.close();

        } catch (IOException e) {
            throw new IllegalArgumentException(e); // todo fix
        }
          Collections.sort(ret);
        return ret;
    }

    public static List<ItemUsage> readItemUsage(File f) {
        List<ItemUsage> ret = new ArrayList<>();
        try {
            LineNumberReader rdr = new LineNumberReader(new FileReader(f));
            String s = rdr.readLine(); // ignore columns
            s = rdr.readLine();
            while(s != null) {
                ret.add(new ItemUsage(s));
                s = rdr.readLine();
            }
            rdr.close();
        } catch (IOException e) {
            throw new IllegalArgumentException(e); // todo fix
        }
        return ret;
    }

    public static  void defineUsage(File f) {
        try {
            List<PointOfInterest> poi = readPointsOfInterest(  f);
            List<String>  types = getTypes(  poi);
            PrintWriter out = new PrintWriter(new FileOutputStream(new File("DataUsage.tsv")) );
            for (String type: types
                 ) {
                out.println(type + "\tunused");
            }
            out.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

    }

    public static List<String> getTypes( List<PointOfInterest> poi) {
        Set<String> types = new HashSet<>();
        for (PointOfInterest p : poi
                ) {
            types.add(p.data_type);

        }
        List<String> ret = new ArrayList<>(types);
        Collections.sort(ret);
        return ret;
    }

    public static Set<String> usedTypes(List<ItemUsage> types)
    {
        Set<String> ret = new HashSet<>();
        for (ItemUsage type : types) {
            if(type.used)
                ret.add(type.name);
        }
        return ret;
    }

    public static List<PointOfInterest> getUsedPoi(List<ItemUsage> types, List<PointOfInterest> poi) {
        List<PointOfInterest> ret = new ArrayList<>();
         Set<String> used = usedTypes(  types);
         for (PointOfInterest p : poi
                ) {
            if(used.contains(p.data_type))
                ret.add(p);

        }

        return ret;
    }

    public static  void savePoi(File outFile,List<PointOfInterest> poi) {
        try {
              PrintWriter out = new PrintWriter(new FileOutputStream(outFile) );
              out.println("Type,Name,Latitude,Longitude,Address");
            for (PointOfInterest p : poi) {
                out.println(
                        p.data_type + "," +
                        p.common_name + "," +
                        Double.toString(p.latitude) + "," +
                        Double.toString(p.longitude) + "," +

                        p.address

                );
            }
            out.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

    }

    /**
     * arg 0 if file of points of interest such as My_Neighborhood.tsv
     * arg 1 if file of usage  such as DataUsage.tsv
     * arg 2 is outfile like PointsOfInterest.csv
     *
     * @param args
     */
    public static void main(String[] args) {
        File data = new File(args[0]);
        File usage = new File(args[1]);
         File outFile = new File(args[2]);
        List<PointOfInterest> poi = readPointsOfInterest(data);
        List<ItemUsage> types = readItemUsage(usage);
        List<PointOfInterest> filtered = getUsedPoi(types,  poi);
        savePoi(  outFile,filtered);
    }
}
