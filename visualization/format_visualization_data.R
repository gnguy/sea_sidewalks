library(data.table); library(scales)

## Import sidewalk observation data
data_dir <- "data"

## Import sidewalk observations with filled-in observation types
sidewalk_observations <- fread(paste0(data_dir, "/sidewalk_obs_cleaned.csv"))

## Import sidewalk verification data, used to map sidewalk lines
sidewalk_verifications <- fread(paste0(data_dir, "/SidewalkVerifications.csv"))

## Import points of interest (POI)s, including schools, bus stops, etc.
poi_data <- fread(paste0(data_dir, "/pois_with_locmeta.csv"))

## Import categorized cost estimates for sidewalks based on information from Seattle DOT
cost_data <- fread(paste0(data_dir, "/ObjectIDCost.csv"))

## Create cost estimates based on cost categorization
cost_data[cost == "LOW", estimated_cost := 1000]
cost_data[cost %in% c("MEDIUM", "MED"), estimated_cost := 5000]
cost_data[cost == "HIGH", estimated_cost := 10000]
cost_data[cost == "0", estimated_cost := 0]
cost_data[is.na(cost), estimated_cost := 0]

## Import and format point of interest distance data (<= 800 feet of a sidewalk)
## From the issues on the sidewalk, take the closest distance between an issue and a POI
## Merge on weights from Seattle DOT closely resembling ADA act guidance on priority/importance
## Collapse to create a weighted priority score based on the distance from 
poi_distances <- fread(paste0(data_dir, "/POI_Near_OBS_Processed_WithIDs.csv"))
poi_distances[Type == "", Type := "Bus Stop"]
poi_distances <- poi_distances[, list(NEAR_DIST = min(NEAR_DIST)), by = c("SWID", "NEAR_POI", "Type")]

poi_priority_weights <- fread(paste0(data_dir, "/Type_Costs_Weights.csv"))
colnames(poi_priority_weights) <- c("Index", "Type", "priority_score")

## Two sets of weights: Double-weighted if within 100 feet of a point of interest, and then if within 800 feet
## Take the first poi_distance observation per SWID 
poi_distances <- merge(poi_distances, poi_priority_weights, by = "Type")

poi_100_ft_scores <- poi_distances[NEAR_DIST <= 100, list(priority_score = sum(priority_score)), by = "SWID"]
poi_800_ft_scores <- poi_distances[, list(priority_score = .5 * sum(priority_score)), by = "SWID"]

priority_scores <- rbindlist(list(poi_100_ft_scores, poi_800_ft_scores), use.names = T)
priority_scores <- priority_scores[, list(priority_score = sum(priority_score)), by = "SWID"]

## Merge neighborhood and council districts onto sidewalk observation data
observation_metadata <- fread(paste0(data_dir, "/sidewalk_obs_locmeta.csv"), select = c("objectid", "C_DISTRICT", "s_hood"))
setnames(observation_metadata, c("C_DISTRICT", "s_hood"), c("council_district", "neighborhood"))
sidewalk_observations <- merge(sidewalk_observations, observation_metadata, by = "objectid")

## Format sidewalk observation variable names for Leaflet, and create dictionary for observation type subsetting
setnames(sidewalk_observations, c("x", "y"), c("longitude", "latitude"))
observation_map <- data.table(raw_name = c("SURFCOND", "HEIGHTDIFF", "OBSTRUCT", "XSLOPE", "OTHER"),
                              formatted_name = c("Surface conditions", "Height difference", "Obstruction", "Cross-slope", "Other"))

### Make surface condition values more legible
sidewalk_observations[surface_condition == "MISSINGLOW", surface_condition := "Missing Section (2x2)"]
sidewalk_observations[surface_condition == "MISSINGMID", surface_condition := "Missing Section (4x4)"]
sidewalk_observations[surface_condition == "MISSINGHI", surface_condition := "Missing Section (8x8)"]
sidewalk_observations[surface_condition == "CRACK<36", surface_condition := "CRACK < 36"]
sidewalk_observations[surface_condition == "CRACK<72", surface_condition := "CRACK < 72"]
sidewalk_observations[surface_condition == "CRACK>72", surface_condition := "CRACK > 72"]


## Create formatted data labels (TODO: Put this in a separate file)
# sidewalk_observations[, formatted_label := paste0("ID: ", objectid, "<br>", "Sidewalk ID: ", sidewalk_unitid, "<br>", "Issue Type: ", observ_type, "<br>")]
sidewalk_observations[, formatted_label := paste0("<br>Issue Type: ", observ_type, "<br>")]
sidewalk_observations[observ_type == "SURFCOND", formatted_label := paste0(formatted_label,
                                                                           "Surface Condition: ", surface_condition)]
sidewalk_observations[observ_type == "HEIGHTDIFF", formatted_label := paste0(formatted_label,
                                                                             "Height difference (inches): ", height_difference, "<br>",
                                                                             "Level difference type: ", level_difference_type, "<br>",
                                                                             "Isolated cross slope: ", isolated_cross_slope, "<br>",
                                                                             "Failing Shim: ", failing_shim)]
sidewalk_observations[observ_type == "OBSTRUCT", formatted_label := paste0(formatted_label,
                                                                           "Obstruction type: ", obstruction_type, "<br>",
                                                                           "Clearance impacted: ", clearance_impacted)]
sidewalk_observations[observ_type == "OBSTRUCT" & clearance_impacted %in% c("HORIZONTAL", "BOTH"), formatted_label := paste0(formatted_label,
                                                                                                                             "<br>",
                                                                                                                             "Width at narrowest point of obstruction: ", minimum_width)]
sidewalk_observations[observ_type == "XSLOPE", formatted_label := paste0(formatted_label,
                                                                         "Isolated cross slope: ", isolated_cross_slope)]
sidewalk_observations[observ_type == "OTHER", formatted_label := paste0(formatted_label,
                                                                        "Sidewalk Feature: ", other_feature)]

## Merge on cost data
sidewalk_observations <- merge(sidewalk_observations, cost_data[, .SD, .SDcols = c("objectid", "estimated_cost")], by = "objectid")

## Collapse from issues to sidewalk-specific problems
sidewalk_dt <- sidewalk_observations[, list(num_issues = length(objectid),
                                            estimated_cost = sum(estimated_cost, na.rm = T),
                                            formatted_label = paste(formatted_label, collapse = "<br>"),
                                            latitude = mean(latitude),
                                            longitude = mean(longitude),
                                            neighborhood = neighborhood[1],
                                            council_district = council_district[1]),
                                     by = "sidewalk_unitid"]

## Add total number and estimated cost to the formatted label
sidewalk_dt[num_issues > 7, formatted_label := ""]
sidewalk_dt[, formatted_cost := dollar_format()(estimated_cost)]
sidewalk_dt[, formatted_label := paste0("Sidewalk ID: ", sidewalk_unitid, "<br>","Total Issues: ", num_issues, "<br>Estimated Total Cost: ", formatted_cost, "<br>", formatted_label)]

## Merge on priority scores to sidewalk observations
sidewalk_dt <- merge(sidewalk_dt, priority_scores, by.x = "sidewalk_unitid", by.y = "SWID", all.x = T)

## If a sidewalk is NA, it is assumed to not have any POI within 100 feet or 800 feet
sidewalk_dt[is.na(priority_score), priority_score := 0]
sidewalk_dt[, weighted_priority_score := priority_score * num_issues]
setorder(sidewalk_dt, -priority_score)

## Create formatted point of interest labels
poi_data[type == "Bus Stop", formatted_label := paste0("Bus Stop <br>", cross_stre, " and ", on_street)]
poi_data[type != "Bus Stop", formatted_label := paste0(type, "<br>", name)]

## Pre-define icons for point of interest data
poi_data[type %in% c("Health Centers - Community", "Health Centers - Public"), icon := "fa-hospital-o"]
poi_data[type %in% c("Elementary Schools", "High Schools", "Higher Education"), icon := "fa-graduation-cap"]
poi_data[type %in% c("Ferry Terminal", "Monorail", "Light Rail", "Bus Stop"), icon := "fa-bus"]
poi_data[type %in% c("Community Centers", "Farmers Markets", "Family Support Center", "Food Banks", "Neighborhood Service Centers"), icon := "fa-users"]
poi_data[type %in% c("Museums and Galleries", "Police Precincts", "General Attractions"), icon := "fa-star"]

save(sidewalk_dt, poi_data, observation_map, file = paste0(data_dir, "/formatted_visualization_data.RData"))
