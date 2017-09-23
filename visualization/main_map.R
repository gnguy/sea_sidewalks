## Main Map
## Shiny App to display an interactive map with all marked sidewalk observations and verifications

## Create the UI
main_map_ui <- function(id, sidewalk_observations, observation_map) { 
  ## Initialize namespace for the UI to connect with the server
  ns <- NS(id)
  
  issue_types <- c("All", unique(observation_map$formatted_name))
  
  fluidPage(
    column(2, 
      selectInput(ns("sel_issue_type"),
                  "Issue Type",
                  choices = issue_types),
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
                            sidewalk_observations, observation_map) {
  
  ###################################################################
  ## Pull current and comparison results, and combine into a dataset
  observation_subset <- reactive({
    if(input$sel_issue_type == "All") {
      observation_subset <- sidewalk_observations
    } else {
      selected_issue_type <- observation_map[formatted_name == input$sel_issue_type, raw_name]
      observation_subset <- sidewalk_observations[OBSERV_TYPE == selected_issue_type,]
    }

    return(observation_subset)
  })
  
  ###################################################################
  ## Generate a main map of 
  output$main_map <- leaflet::renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addMarkers(data = observation_subset(),
                 clusterOptions = markerClusterOptions(),
                 popup = ~formatted_label)
  })


  ###################################################################
  ## Display all tables, scatters, etc.
  output$point_table <- DT::renderDataTable({
    DT::datatable(observation_subset(), 
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
      write_csv(observation_subset(), con)
    }
  )
}

