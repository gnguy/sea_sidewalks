import pandas as pd
import geopandas as gpd
from geopandas.tools import sjoin
from shapely.geometry import Point


def clean_data(df):
    """ Fill in missing observation types based on the information given about
    specific obstructions.
    Arguments:
        df : a pandas DataFrame
             A DataFrame containing the sidewalk obstruction observations from
             data.seattle.gov
    Output:
        a cleaned pandas DataFrame with NaNs filled in appropriately
    """
    # Missing observation types for some obstructions; add it in if an
    #   obstruction_type was filled in
    df.loc[(df.observ_type.isnull()) & df.obstruction_type.notnull(),
           'observ_type'] = 'OBSTRUCTION'
    # "Failing_shim" only filled in if "N" -- fill in the NaNs
    df.loc[df.failing_shim.isnull(), 'failing_shim'] = "N"
    # Missing observation types for some heigh differences; add it in if
    #   a height difference was filled in
    df.loc[(df.observ_type.isnull()) & (df.level_difference_type.notnull()),
           'observ_type'] = 'HEIGHTDIFF'
    # Missing observation types for some surface conditions; add it in if a
    #   surface condition was filled in
    df.loc[(df.observ_type.isnull()) & (df.surface_condition.notnull()),
           'observ_type'] = 'SURFCOND'
    # Missing observation types for some other features; add them in if
    #  an other feature was filled in
    df.loc[(df.observ_type.isnull()) & (df.other_feature.notnull()),
           'observ_type'] = 'OTHER'
    # Missing observations for some cross slopes; add them in if the
    #   cross slope is not null and no other values are present for other
    #   surface conditions
    df.loc[(df.observ_type.isnull()) & (df.isolated_cross_slope.notnull()) &
           (df.surface_condition.isnull()) & (df.height_difference.isnull()),
           'observ_type'] = 'XSLOPE'

    return df


def add_location_info(obs, hoods, cds):
    """ Add the neighborhood and council district that each obstruction is
    found in.
    Arguments:
        obs : a pandas DataFrame
              A pandas DataFrame containing the sidewalk obstruction data from
              data.seattle.gov
        hoods : a geopandas GeoDataFrame
                a GeoDataFrame containing the neighborhood delineation polygons
                from data.seattle.gov
        cds : a geopandas GeoDataFrame
              a GeoDataFrame containing the council district delineation polygons
              from data.seattle.gov
    Output: a dataframe linking obstruction ids to neighborhoods and council
            districts."""

    # Add human-readable neighborhood information columns
    hoods.columns = [c.lower() for c in list(hoods)]
    obs_loc = obs[['x', 'y', 'objectid', 'sidewalk_unitid', 'globalid']]
    obs_geom = [Point(xy) for xy in zip(obs_loc.x, obs_loc.y)]
    obs_loc = gpd.GeoDataFrame(obs_loc, geometry=obs_geom)
    obs_loc.crs = hoods.crs
    obs_with_hood = gpd.sjoin(obs_loc, hoods, how='left')
    obs_with_hood = obs_with_hood[['hoods_', 'hoods_id', 's_hood', 'l_hood',
                                   'l_hoodid', 'objectid']]
    # Add human-readable council district information columns
    cds.columns = [c.lower() for c in list(cds)]
    obs_with_cd = gpd.sjoin(obs_loc, cd, how='left')
    obs_with_cd = []['c_district', 'display_na', 'objectid']]

    # Merge the two location data tables on unique objectid keys
    obs_with_locs = obs_with_hood.merge(obs_with_cd, on='objectid')
    return obs_with_locs


def main(obs):
    print("Cleaning data")
    clean_obs = clean_data(obs)
    clean_obs.to_csv(data_dir+"/sidewalk_obs_cleaned.csv")
    print("Gathering neighborhood and district information")
    obs_loc_data = add_location_info(clean_obs)
    obs_loc_data.to_csv(data_dir+"/sidewalk_obs_locmeta.csv")
    print("Done. Datasets saved.")


if __name__ == "__main__":
    obs = pd.read_csv(rawdata_dir+"/SidewalkObservations.csv")
    hoods = gpd.GeoDataFrame.from_file(
        rawdata_dir+"/Neighborhoods/WGS84/Neighborhoods.shp")
    cds = gpd.GeoDataFrame.from_file(
        rawdata_dir+"/Council_Districts/Council_districts.shp")
