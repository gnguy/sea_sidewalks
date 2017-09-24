## Main Map
## Shiny App to display an interactive map with all marked sidewalk observations and verifications

## Create the UI
main_map_ui <- function(id, sidewalk_observations, observation_map, poi_data) { 
  ## Initialize namespace for the UI to connect with the server
  ns <- NS(id)
  
  issue_types <- c("All", unique(observation_map$formatted_name))
  council_opts <- paste0("Council District ", unique(sidewalk_observations$council_district))
  neighborhood_opts <- c("All", unique(sidewalk_observations$neighborhood))
  
  fluidPage(
    column(2, 
      selectInput(ns("sel_issue_type"),
                  "Issue Type",
                  choices = issue_types),
      selectInput(ns("sel_neighborhood"),
                  "Neighborhood",
                  choices = neighborhood_opts),
      checkboxInput(ns("toggle_top_priority"), "Display Top Priority Issues", FALSE),
      conditionalPanel(condition = paste0("input['", ns("toggle_top_priority"), "'] == true"),
                        numericInput(ns("sel_top_number"),
                                    "Number of Top Priority Issues",
                                    min = 1, max = 500, value = 100)
      ),
      checkboxInput(ns("toggle_pois"), "Display Points of Interest (POIs)", FALSE),
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
    observation_subset[, Priority := runif(nrow(observation_subset), 1, 5)]
    setorder(observation_subset, -Priority)

    return(observation_subset)
  })

  top_point_geo_subset <- reactive({
    if(input$toggle_top_priority == FALSE) {
      top_point_geo_subset <- observation_subset()
    } else {
      top_point_geo_subset <- head(observation_subset(), input$sel_top_number)
    }
    return(top_point_geo_subset)
  })

  poi_icon_values <- reactiveValues()
  
  poi_geo_subset <- reactive({
    poi_geo_subset <- copy(poi_data)
    if(input$sel_neighborhood != "All") poi_geo_subset <- poi_geo_subset[s_hood == input$sel_neighborhood]
    
    poi_icons <- data.table(poi_type = poi_geo_subset$Type)
    poi_icons[poi_type %in% c("Health Centers - Community", "Health Centers - Public"), icon := "fa-hospital-o"]
    poi_icons[poi_type %in% c("Elementary Schools", "High Schools", "Higher Education"), icon := "fa-graduation-cap"]
    poi_icons[poi_type %in% c("Ferry Terminal", "Monorail", "Light Rail"), icon := "fa-bus"]
    poi_icons[poi_type %in% c("Community Centers", "Farmers Markets", "Family Support Center", "Food Banks", "Neighborhood Service Centers"), icon := "fa-users"]
    poi_icons[poi_type %in% c("Museums and Galleries", "Police Precincts", "General Attractions"), icon := "fa-star"]
    
    leafIcons <- awesomeIcons(
      icon = poi_icons$icon,
      library = "fa"
    )
    
    poi_icon_values$value <- leafIcons
    
    return(poi_geo_subset)
  })

  
  ###################################################################
  ## Generate a main map of 
  output$main_map <- leaflet::renderLeaflet({
    if(input$toggle_top_priority == FALSE) {
      leaf_plot <- leaflet() %>%
                    addTiles() %>%
                    addMarkers(data = top_point_geo_subset(),
                               clusterOptions = markerClusterOptions(),
                               popup = ~formatted_label)
      if(input$toggle_pois == TRUE) leaf_plot <- addAwesomeMarkers(leaf_plot, data = poi_geo_subset(), icon = poi_icon_values$value)
    } else {
      leaf_plot <- leaflet() %>%
                  addTiles() %>%
                  addMarkers(data = top_point_geo_subset(),
                             popup = ~formatted_label)
      if(input$toggle_pois == TRUE) leaf_plot <- addAwesomeMarkers(leaf_plot, data = poi_geo_subset(), icon = poi_icon_values$value)
    }
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

