library(shiny)
library(DT)
library(rvest)
library(stringr)
library(dplyr)
library(zoo)

shinyServer(function(input, output) {
  
  results <- eventReactive(input$gobutton, {
    #needs some validation
    username <- input$username
    month <- as.yearmon(input$month)
    startdate <- as.Date(month)
    enddate <- as.Date(month, frac = 1)
    
    userplays <- read_html(paste0("https://boardgamegeek.com/plays/bygame/user/",
                                  str_replace(username," ","%20"),
                                  "/subtype/boardgame/start/",
                                  startdate,
                                  "/end/",
                                  enddate))
    
    games <- userplays %>%
      html_nodes("#main_content tr+ tr a") %>%
      html_text
    
    validate(
      need(length(games) > 0, 
           "No plays found for that user in that month. Please check username and try again"))
    
    game_ids <- userplays %>%
      html_nodes("#main_content tr+ tr a") %>%
      html_attr("href") %>%
      str_replace("/[:alpha:]+/", "") %>%
      str_replace ("/.+","")
    
    get_players <- function(game_id, month, username){
      
      gameplays <- read_html(paste0("https://boardgamegeek.com/playstats/thing/",
                                    game_id,
                                    "/",
                                    format(month, "%Y-%m")))
      
      players <- gameplays %>%
        html_nodes(".username a") %>%
        html_text %>%
        sort
      
      otherplayers <- paste(players[players != username], collapse = ", ")
      
      data_frame(id = game_id, nplayers = length(players), players = otherplayers) 
      
    }
    
    game_df <- bind_rows(lapply(game_ids, get_players, month, username))
    
    game_df$name <- games
    
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
