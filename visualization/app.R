## Base Shiny layout for UI and server namespaces for all child scripts
library(shiny)
library(data.table)
library(plotly)
library(formattable)
library(shinythemes)
library(RColorBrewer)
library(ggplot2)
library(scales)
library(leaflet)
library(readr)
library(htmltools)

## Import sidewalk observation data
data_dir <- "~/Documents/Git/sea_sidewalks/input_data"

sidewalk_observations <- fread(file.path(data_dir, "sidewalk_obs_cleaned.csv"))
sidewalk_verifications <- fread(file.path(data_dir, "SidewalkVerifications.csv"))
poi_data <- fread(file.path(data_dir, "pois_with_locs.csv"))

observation_metadata <- fread(file.path(data_dir, "sidewalk_obs_locmeta.csv"), select = c("objectid", "C_DISTRICT", "s_hood"))
setnames(observation_metadata, c("C_DISTRICT", "s_hood"), c("council_district", "neighborhood"))
sidewalk_observations <- merge(sidewalk_observations, observation_metadata, by = "objectid")

setnames(sidewalk_observations, c("x", "y"), c("longitude", "latitude"))
observation_map <- data.table(raw_name = c("SURFCOND", "HEIGHTDIFF", "OBSTRUCT", "XSLOPE", "OTHER"),
                              formatted_name = c("Surface conditions", "Height difference", "Obstruction", "Cross-slope", "Other"))

## Create formatted data labels (TODO: Put this in a separate file)
sidewalk_observations[, formatted_label := paste0("ID: ", objectid, "<br>", "Sidewalk ID: ", sidewalk_unitid, "<br>", "Issue Type: ", observ_type, "<br>")]
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

## Source all of the visualization code
source("main_map.R")

## Source helper functions
source("summarize_data.R")
# source("report_card.R")

## Create the UI -- adding an age button to view all ages, or sub-select to one age group
ui <- function(request) { 
  navbarPage("SEA Sidewalks",
    # shinythemes::themeSelector(),  # To play around with UI themes
    theme = shinytheme("paper"),
    tabPanel("Main Map", main_map_ui("main_map", 
                                     sidewalk_observations = sidewalk_observations,
                                     observation_map = observation_map,
                                     poi_data = poi_data))
    # tabPanel("Report Card", report_card_ui("report_card", 
    #                                  sidewalk_observations = sidewalk_observations,
    #                                  observation_map = observation_map))
  )
}


server <- function(input,output,session) {
  callModule(main_map_server, "main_map",
             sidewalk_observations = sidewalk_observations,
             observation_map = observation_map,
             poi_data = poi_data)
  # callModule(report_card_server, "report_card",
  #            sidewalk_observations = sidewalk_observations,
  #            observation_map = observation_map)
}

shinyApp(ui,server)
