## Main Map
## Shiny App to display an interactive map with all marked sidewalk observations and verifications

## Create the UI
main_map_ui <- function(id, sidewalk_observations, observation_map, poi_data) { 
  ## Initialize namespace for the UI to connect with the server
  ns <- NS(id)
  
  issue_types <- c("All", sort(unique(observation_map$formatted_name)))
  council_opts <- paste0("Council District ", unique(sidewalk_observations$council_district))
  neighborhood_opts <- c("All", sort(unique(sidewalk_observations$neighborhood)))
  
  fluidPage(
    column(2, 
      selectInput(ns("sel_issue_type"),
                  "Issue Type",
                  choices = issue_types),
      selectInput(ns("sel_neighborhood"),
                  "Neighborhood",
                  choices = neighborhood_opts),
      radioButtons(ns("toggle_sidewalk"), "Display Sidewalks or Reported Issues", choices = c("Sidewalks", "Issues"), selected = "Issues"),
      checkboxInput(ns("toggle_top_priority"), "Display Top Priority Issues", FALSE),
      conditionalPanel(condition = paste0("input['", ns("toggle_top_priority"), "'] == true"),
                        numericInput(ns("sel_top_number"),
                                    "Number of Top Priority Issues",
                                    min = 1, max = 500, value = 100),
                       checkboxInput(ns("toggle_number_weighting"), "Weight Priority by Number of Issues", FALSE)
      ),
      checkboxInput(ns("toggle_pois"), "Display Points of Interest (POIs)", FALSE),
      conditionalPanel(condition = paste0("input['", ns("toggle_pois"), "'] == true"),
                       checkboxInput(ns("toggle_buses"), "Display Bus Stops", FALSE)
      ),
      downloadButton(ns("download_data"),"Download Table")
    ),
    column(10,
           # Show a table view of the relative change results
           tabsetPanel(
             tabPanel("Main Map",
                      leaflet::leafletOutput(ns("main_map"), height = 800)
             ),
             tabPanel("Point Table", DT::dataTableOutput(ns("point_table")))
           )
    )
  )
}


###################################################################
## Set the Server for the visualization

main_map_server <- function(input, output, session, 
                            sidewalk_observations, observation_map, poi_data) {
  
  ###################################################################
  ## Pull current and comparison results, and combine into a dataset
  observation_subset <- reactive({
    observation_subset <- copy(sidewalk_observations)
    if(input$sel_neighborhood != "All") observation_subset <- observation_subset[neighborhood == input$sel_neighborhood]
    if(input$sel_issue_type != "All") {
      selected_issue_type <- observation_map[formatted_name == input$sel_issue_type, raw_name]
      observation_subset <- observation_subset[observ_type == selected_issue_type,]
    }

    return(observation_subset)
  })

  top_point_geo_subset <- reactive({
    top_point_geo_subset <- copy(observation_subset())
    if(input$toggle_top_priority == TRUE) {
      if(input$toggle_number_weighting == TRUE) { 
        setorder(top_point_geo_subset, -weighted_priority_score)
      } else {
        setorder(top_point_geo_subset, -priority_score)
      }
      top_point_geo_subset <- head(top_point_geo_subset, input$sel_top_number)
    }
    return(top_point_geo_subset)
  })
  
  ## For the table display, mark explicitly which columns to keep in the data table view and download CSV
  table_display_subset <- reactive({
    if(input$toggle_sidewalk == "Sidewalks") keep_cols <- c()
    if(input$toggle_sidewalk == "Issues") keep_cols <- c()
    table_display_subset <- top_point_geo_subset()[, .SD, .SDcols = keep_cols]
    
    return(table_display_subset)
  })

  poi_icon_values <- reactiveValues()
  
  poi_geo_subset <- reactive({
    poi_geo_subset <- copy(poi_data)
    if(input$sel_neighborhood != "All") poi_geo_subset <- poi_geo_subset[S_HOOD == input$sel_neighborhood]
    if(input$toggle_buses == F) poi_geo_subset <- poi_geo_subset[type != "Bus Stop"]
    
    leafIcons <- awesomeIcons(
      icon = poi_geo_subset$icon,
      library = "fa",
      markerColor = "green"
    )
    
    poi_icon_values$value <- leafIcons
    return(poi_geo_subset)
  })
  
  ###################################################################
  ## Generate a main map of 
  output$main_map <- leaflet::renderLeaflet({
    leaf_plot <- leaflet() %>%
                  addTiles()
    
    ## If showing the top-priority points, render each point individually. Otherwise, allow clustering.
    if(input$toggle_top_priority == FALSE & input$sel_neighborhood == "All") {
      leaf_plot <- addMarkers(leaf_plot,
                              data = top_point_geo_subset(),
                              clusterOptions = markerClusterOptions(),
                              popup = ~formatted_label)
    } else {
      leaf_plot <- addMarkers(leaf_plot,
                              data = top_point_geo_subset(),
                              popup = ~formatted_label)
      
    }
    
    ## Add points of interest if desired
    if(input$toggle_pois == TRUE) leaf_plot <- addAwesomeMarkers(leaf_plot, 
                                                                 data = poi_geo_subset(), 
                                                                 icon = poi_icon_values$value,
                                                                 popup = ~formatted_label)
    leaf_plot
  })


  ###################################################################
  ## Display all tables, scatters, etc.
  output$point_table <- DT::renderDataTable({
    DT::datatable(top_point_geo_subset(), 
                  rownames=F,
                  filter=list(position="top",plain=T),
                  options=list(
                    autoWidth=T,pageLength=50,
                    scrollX=TRUE
                  )
    )
  })

  ## Download the overall data
  output$download_data <- downloadHandler(
    filename=function() {
      paste0("map_data_", input$sel_issue_type, "_",
        format(Sys.time(),"%Y-%m-%d_%I-%M-%p"),
        ".csv")
    },
    content=function(con) {
      write_csv(top_point_geo_subset(), con)
    }
  )
}

