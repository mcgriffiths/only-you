library(dplyr)
library(shiny)
library(shinycssloaders)

shinyUI(fluidPage(
  
  # Application title
  titlePanel("Games only you played this month"),
  
  # Sidebar 
  sidebarLayout(
    sidebarPanel(
       textInput("username", "Username:"),
       selectInput("month", "Month:", 
                   choices = format(seq(as.Date(format(Sys.Date(),"%Y-%m-01")), by = "-1 month", length.out= 24),"%B %Y")),
       actionButton("gobutton","Go")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       DT::dataTableOutput("results_table") %>% withSpinner(type=5)
    )
  )
))
