library(shiny)
library(DT)
library(rvest)
library(stringr)
library(dplyr)
library(zoo)
library(xml2)
library(shinycssloaders)

shinyServer(function(input, output) {
  
  results <- eventReactive(input$gobutton, { #set up so nothing happens until button clicked
    
    username <- input$username
    month <- as.yearmon(input$month)
    startdate <- as.Date(month)
    enddate <- as.Date(month, frac = 1) #get last day of month
    
    #scrape user's monthly play page
    userplays <- read_xml(paste0("https://boardgamegeek.com/xmlapi2/plays?username=",
                                  str_replace(username," ","%20"),
                                  "&mindate=",
                                  startdate,
                                  "&maxdate=",
                                  enddate))
    
    #get items
    items <- userplays %>%
      xml_find_all(".//play/item") 
    
    #throw error if no games
    validate(
      need(length(items) > 0, 
           "No plays found for that user in that month. Please check username and try again"))
    
    games <- unique(xml_attr(items, "name"))
    game_ids <- unique(xml_attr(items,"objectid"))
    
    #function to find all players of a game 
    get_players <- function(game_id, month, username){
      
      #scrape game's montly plays page
      gameplays <- read_html(paste0("https://boardgamegeek.com/playstats/thing/",
                                    game_id,
                                    "/",
                                    format(month, "%Y-%m")))
      
      #get all players
      players <- gameplays %>%
        html_nodes(".username a") %>%
        html_text %>%
        sort
      
      #remove self 
      otherplayers <- paste(players[players != username], collapse = ", ")
      
      data_frame(id = game_id, nplayers = length(players), players = otherplayers) 
      
    }
    
    #put all results together
    game_df <- bind_rows(lapply(game_ids, get_players, month, username))
    game_df$name <- games
    
    #set up final output
    game_df <- game_df %>%
      arrange(nplayers) %>%
      filter(nplayers < 100) %>%
      select(name, nplayers, players) 
    
    game_df
    
  })
  
  output$results_table <- DT::renderDataTable({
    results() 
  },
  colnames = c("Game", "Players", "Usernames of other players"),
  rownames = FALSE,
  options = list(searching = FALSE,
                 paging = FALSE,
                 autowidth = TRUE,
                 columnDefs = list(list(width="200px", targets = list(0)))))
  
})
