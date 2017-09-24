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

sidewalk_observations <- fread(file.path(data_dir, "SidewalkObservations.csv"))
sidewalk_verifications <- fread(file.path(data_dir, "SidewalkVerifications.csv"))
observation_metadata <- fread(file.path(data_dir, "sidewalk_obs_locmeta.csv"), select = c("objectid", "C_DISTRICT", "s_hood"))
setnames(observation_metadata, c("objectid", "C_DISTRICT", "s_hood"), c("OBJECTID", "council_district", "neighborhood"))
sidewalk_observations <- merge(sidewalk_observations, observation_metadata, by = "OBJECTID")

setnames(sidewalk_observations, c("X", "Y"), c("longitude", "latitude"))
observation_map <- data.table(raw_name = c("SURFCOND", "HEIGHTDIFF", "OBSTRUCT", "XSLOPE", "OTHER"),
                              formatted_name = c("Surface conditions", "Height difference", "Obstruction", "Cross-slope", "Other"))

## Create formatted data labels (TODO: Put this in a separate file)
sidewalk_observations[, formatted_label := paste0("ID: ", OBJECTID, "<br>", "Sidewalk ID: ", SIDEWALK_UNITID, "<br>", "Issue Type: ", OBSERV_TYPE, "<br>")]
sidewalk_observations[OBSERV_TYPE == "SURFCOND", formatted_label := paste0(formatted_label,
                                                                           "Surface Condition: ", SURFACE_CONDITION)]
sidewalk_observations[OBSERV_TYPE == "HEIGHTDIFF", formatted_label := paste0(formatted_label,
                                                                             "Height difference (inches): ", HEIGHT_DIFFERENCE, "<br>",
                                                                             "Level difference type: ", LEVEL_DIFFERENCE_TYPE, "<br>",
                                                                             "Isolated cross slope: ", ISOLATED_CROSS_SLOPE, "<br>",
                                                                             "Failing Shim: ", FAILING_SHIM)]
sidewalk_observations[OBSERV_TYPE == "OBSTRUCT", formatted_label := paste0(formatted_label,
                                                                           "Obstruction type: ", OBSTRUCTION_TYPE, "<br>",
                                                                           "Clearance impacted: ", CLEARANCE_IMPACTED)]
sidewalk_observations[OBSERV_TYPE == "OBSTRUCT" & CLEARANCE_IMPACTED %in% c("HORIZONTAL", "BOTH"), formatted_label := paste0(formatted_label,
                                                                                                                             "<br>",
                                                                                                                             "Width at narrowest point of obstruction: ", MINIMUM_WIDTH)]
sidewalk_observations[OBSERV_TYPE == "XSLOPE", formatted_label := paste0(formatted_label,
                                                                         "Isolated cross slope: ", ISOLATED_CROSS_SLOPE)]
sidewalk_observations[OBSERV_TYPE == "OTHER", formatted_label := paste0(formatted_label,
                                                                        "Sidewalk Feature: ", OTHER_FEATURE)]

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
                                     observation_map = observation_map))
    # tabPanel("Report Card", report_card_ui("report_card", 
    #                                  sidewalk_observations = sidewalk_observations,
    #                                  observation_map = observation_map))
  )
}


server <- function(input,output,session) {
  callModule(main_map_server, "main_map",
             sidewalk_observations = sidewalk_observations,
             observation_map = observation_map)
  # callModule(report_card_server, "report_card",
  #            sidewalk_observations = sidewalk_observations,
  #            observation_map = observation_map)
}

shinyApp(ui,server)
