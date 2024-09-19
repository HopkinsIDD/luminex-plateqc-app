###----- App for Luminex assay plate QC checks -----###

library(shiny)
library(bslib)
library(quarto)
library(data.table)


ui <- fluidPage(
  
  #--- App title 
  titlePanel("Multiplex Plate QC"),
  
  
  #--- Upload button for plate read csv
  sidebarLayout(sidebarPanel( 
    fileInput("upload", NULL, accept='.csv', buttonLabel = "Upload csv", multiple = F),
   ),
  
  #--- Main panel for generating html report 
  mainPanel(
    
    # Text / instructions
    p("Here you can generate a report of some quality control assessments for an indivdual plate run.
      You can upload XPONENT .csv files of raw plate readouts from Luminex Intelliflex or MagPix machines.",
      br(),
      "Currently this will work only for the Nepal NMC serosurvey plate data. 
      Once final plate layouts have been defined for SeroChit and National serostudies, 
      we will update this app to work for these studies too.",
      br(),
      "In the case where sample labels were not successfully saved to the XPONENT output, the report will not work.
      Please email megan.odriscoll@hug.ch with the XPONENT .csv file and the sample labels .csv file."),
    
    # Download button
    downloadButton('report', "Generate report", align="center", style="color:green;
                   text-align:center")
    
    
   )
  )
)




server <- function(input, output) {
  
  
  #--- data from csv
  rawdata <- reactive({
    if(is.null(input$upload)) return(NULL)
    else{
      df <- fread(input$upload$datapath, fill=T)
      return(df)
    }
  })
  
  
  #--- plate name from csv
  plate_name <- reactive({
     df <- as.data.frame(rawdata())
     plate_name <- df$V2[df$V1=='Batch']
     plate_name
   })
  
  #--- control labels
  ctrl_labs <- reactive({
    file <- "ControlLabels.csv"
    read.csv(file)
  })
  
  #--- data from previous runs
  prev_runs <- reactive({
    file <- "PrevRuns.csv"
    read.csv(file)
  })
  
  
  #--- Generate & download html report
  output$report <- downloadHandler(
    
    
    filename = 'QCReport.html',
  
    content <- function(file){
    
        # Copy the report file to a temporary directory before processing it, in
        # case we don't have write permissions to the current working dir (which
        # can happen when deployed).
        tempReport <- file.path(tempdir(), 'QCReport.qmd')
        file.copy("QCReport.qmd", tempReport, overwrite = TRUE)
        
        # Set up parameters to pass to Rmd document
        params <- list(raw=rawdata(), plate_name=plate_name(), ctrl_labs=ctrl_labs(), prev_runs=prev_runs())
        
        # Knit the document, passing in the `params` list, and eval it in a
        # child of the global environment (this isolates the code in the document
        # from the code in this app).
        quarto_render(tempReport, execute_params = params, execute_dir = tempdir())
  }
  )

}


shinyApp(ui = ui, server = server)

