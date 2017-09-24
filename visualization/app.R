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

## Import initial data (from format_visualization_data.R)
data_dir <- "data"
load(paste0(data_dir, "/formatted_visualization_data.RData"))

## Source all of the visualization code
source("main_map.R")

## Source helper functions
# source("summarize_data.R")
# source("report_card.R")

## Create the UI -- adding an age button to view all ages, or sub-select to one age group
ui <- function(request) { 
  navbarPage("SEA Sidewalks",
    # shinythemes::themeSelector(),  # To play around with UI themes
    theme = shinytheme("paper"),
    tabPanel("Main Map", main_map_ui("main_map", 
                                     sidewalk_observations = sidewalk_dt,
                                     observation_map = observation_map,
                                     poi_data = poi_data))
  )
}


server <- function(input,output,session) {
  callModule(main_map_server, "main_map",
             sidewalk_observations = sidewalk_dt,
             observation_map = observation_map,
             poi_data = poi_data)
}

shinyApp(ui,server)
