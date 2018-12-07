library(dplyr)
library(shiny)
library(shinycssloaders)

shinyUI(navbarPage('qwerty tools',
  
  # Application title
  tabPanel("Only you",
  
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
  ),
  
  tabPanel("Five years ago",
           sidebarLayout(
             sidebarPanel(
               textInput("username_5", "Username:"),
               actionButton("gobutton_5","Go"),
               numericInput("end_year", "End year:", 2018, min = 2000, max = 2018, step = 1),
               numericInput("start_year", "Start year:", 2013, min = 2000, max = 2018, step = 1)
             ),
             
             # Show a plot of the generated distribution
             mainPanel(
               DT::dataTableOutput("all_years") %>% withSpinner(type=5)
             )
           )
           
           
           )
  
  )
)
