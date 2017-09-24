import pandas as import pd


def generate_talking_points(obs, ver):
    """ Make a snazzy summary list of some important metrics.
    Arguments:
        obs : a pandas Dataframe
              Dataframe containing sidewalk obstruction observations
        ver : a pandas Dataframe
              DataFrame containing sidewalk characteristic information
    Output: a string containing talking points with important numbers from the
            data.
    """
    # Total number of observations over sidewalks
    obs_n = len(obs.objectid.unique())
    sw_n = len(obs.sidewalk_unitid.unique())

    # Number that aren't wide enough for wheelchairs
    ver.columns = [c.lower() for c in list(ver)]
    ver_ws = ver_ws[['sidewalk_width', 'variable_width',
                     'unitid']]
    widths = obs[['objectid', 'sidewalk_unitid',
                  'minimum_width']]
    ver_ws.rename(columns={'unitid': 'sidewalk_unitid'},
                  inplace=True)
    widths = widths.merge(ver_ws, on ='sidewalk_unitid', how='left')
    not_wide = widths.loc[(widths.sidewalk_width < 36) |
                          (widths.minimum_width < 36) |
                          (widths.variable_width < 36), :]
    not_wide_n = float(len(not_wide.sidewalk_unitid.unique()))
    total_n = float(len(widths.sidewalk_unitid.unique()))
    not_wide_percent = not_wide_n/total_n

    # Largest obstruction
    max_ob = obs.height_difference.max()

    string = ("There are {obs_n} obstructions on {obs_sw} sidewalks in Seattle."
              "\n That means that {perc}% of sidewalks have obstructions."
              "\n Nearly {not_wide} of sidewalks in Seattle are not wide enough "
              "to allow for safe passage of wheelchairs."
              "The largest obstruction is a height gap {inc} inches tall.")\
        .format(obs_n = obs_n,
                obs_sw = sw_n,
                perc = round(float(obs_n)/float(sw_n)*100.0)
                not_wide = round(not_wide_percent*100.0)
                inc  = max_ob)
    return string


def main(obs, ver):
    talking_points = generate_talking_points(obs, ver)
    print(talking_points)


if __name__ == "__main__":
    so = pd.read_csv(data_dir+"/sidewalk_obs_cleaned.csv')
    sv = pd.read_csv(data_dir+"/SidwalkVerifications.csv')
