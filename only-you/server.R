library(shiny)
library(DT)
library(rvest)
library(stringr)
library(dplyr)
library(zoo)
library(xml2)
library(shinycssloaders)
library(purrr)
library(tidyr)
library(lubridate)

shinyServer(function(input, output) {
  
  results <- eventReactive(input$gobutton, { #set up so nothing happens until button clicked
    
    username <- input$username
    month <- as.yearmon(input$month)
    startdate <- as.Date(month)
    enddate <- as.Date(month, frac = 1) #get last day of month

    userplays_string <- paste0("https://boardgamegeek.com/xmlapi2/plays?username=",
                               str_replace(username," ","%20"),
                               "&mindate=",
                               startdate,
                               "&maxdate=",
                               enddate)
    
    #scrape user's monthly play page
    userplays <- read_xml(userplays_string)
    totplays <- userplays %>% xml_attr('total') %>% as.integer
    pages <- ceiling(totplays/100)

    if(pages > 1){

      for (i in 2:pages){

        page <- read_xml(paste0(userplays_string,
                                "&page=",
                                i))

        pagechildren <- xml_children(page)

        for (child in pagechildren) {
          xml_add_child(userplays, child)
        }
      }
    }
    
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
    game_df <- map_df(game_ids, get_players, month, username)
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
  
  #main function to get 5 year plays
  all_years <- eventReactive(input$gobutton_5, { #set up so nothing happens until button clicked
    read_page <- function(pagenum, username){
      Sys.sleep(2) # time delay to play nice with BGG
      
      # create URL from username and page number
      page_string <- paste0('https://www.boardgamegeek.com/xmlapi2/plays?username=',
                            username,
                            '&page=',
                            pagenum)
      
      plays <- read_xml(page_string) # read the XML
      
      # now parse the required fields from the XML
      date <- plays %>% xml_find_all('//play') %>% xml_attr('date') %>% as.Date()
      quantity <- plays %>% xml_find_all('//play') %>% xml_attr('quantity') %>% as.integer()
      id <- plays %>% xml_find_all('//play/item') %>% xml_attr('objectid')
      name <- plays %>% xml_find_all('//play/item') %>% xml_attr('name')
      
      # and put them in a data frame to return
      data_frame(date, quantity, id, name)
    }
    
    page_string <- paste0('https://www.boardgamegeek.com/xmlapi2/plays?username=', input$username_5)
    
    # get total plays and convert to total number of pages to retrieve
    tot_plays <- read_xml(page_string) %>% xml_attr('total') %>% as.integer()
    pages <- ceiling(tot_plays / 100)
    
    #read all plays pages into one data frame using purrr::map_df to iterate
    map_df(1:pages, read_page, input$username_5)
    
  })
  
  output$all_years <- DT::renderDataTable({
    all_years() %>%
      mutate(year = year(date)) %>%
      arrange(name, year) %>%
      group_by(name, id, year) %>%
      summarise(quantity = sum(quantity)) %>%
      filter(year <= input$end_year) %>%
      filter(first(year) == input$start_year, 
             n() >= input$end_year - input$start_year)
  })
  
})
