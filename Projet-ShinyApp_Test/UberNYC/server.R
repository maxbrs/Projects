
# Source : https://www.credera.com/blog/business-intelligence/twitter-analytics-using-r-part-1-extract-tweets/

library(shiny)
library(twitteR)
library(ROAuth)
library(tm)
library(wordcloud)
library(leaflet)
library(dplyr)
library(ggplot2)
library(ggmap)
library(rgdal)
library(zoo)
# library(shinyAce)
# library(sendmailR)

# Function to get Tweets from Tweeter
load("twitter_authentication.Rdata")

CUSTOMER_KEY <- "PuVwmsMpaPu1M9LU4U81FearN"
CUSTOMER_SECRET <- "f4ewMqLObXH9IjKsEs4GeTfpeLlGeYhh2cfJmgaPOWVMsTcw6b"
ACCESS_TOKEN <- "897396647201734656-dnVPdSyMqTFsDnmS8qJnzdN89F26mfv"
ACCESS_secret <- "QLE43qf9a4iYGVq4LC8u48TXXq3M5uGBVYRvbYSiigDQ2"
setup_twitter_oauth(CUSTOMER_KEY, CUSTOMER_SECRET, ACCESS_TOKEN, ACCESS_secret)

getTweets <- function(word, number_tweets = 750, number_plot = 100){
  
  tweets <- searchTwitter(word, n=number_tweets)#, lang="en")
  tweets.text <- sapply(tweets, function(x) x$getText())
  
  # Cleaning the tweets
  tweets.text <- sapply(tweets.text,function(x) iconv(x, "latin1", "ASCII", sub=""))
  # Deal with english bad words
  # Deal with fr bad words
  tweets.text <- gsub("[[:punct:]]", "", tweets.text)
  tweets.text <- tolower(tweets.text)
  tweets.text <- gsub("rt", "", tweets.text)
  tweets.text <- gsub("@\\w+", "", tweets.text)
  tweets.text <- gsub("http\\w+", "", tweets.text)
  tweets.text <- gsub("[ |\t]{2,}", "", tweets.text)
  tweets.text <- gsub("^ ", "", tweets.text)
  tweets.text <- gsub(" $", "", tweets.text)
  tweets.text <- gsub(tolower(word), "", tweets.text)
  
  #clean up by removing stop words
  tweets.text.corpus <- Corpus(VectorSource(tweets.text))
  tweets.text.corpus <- tm_map(tweets.text.corpus, function(x)removeWords(x,stopwords()))

  #generate wordcloud
  set.seed(1)
  wordcloud(tweets.text.corpus, min.freq = 2, colors=brewer.pal(8, "Dark2"), random.color= T, random.order = F, max.words = number_plot)
}

# Load the uber data (from april to sept 2014)
data4 <- read.csv("uber-raw-data-4-14.csv")
data <- data4

coord <- data.frame(lon = -74.00594, lat = 40.71278)


# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  # observe({
  #   if(is.null(input$send) || input$send==0) {return(NULL)}
  #   from <- isolate(input$from)
  #   # to <- isolate(input$to)
  #   to <- "maxbriens@gmail.com"
  #   subject <- isolate(input$subject)
  #   msg <- isolate(input$message)
  #   sendmail(from, to, subject, msg)
  # })
  
  output$distPlot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    
    # draw the histogram with the specified number of bins
    hist(x, breaks = bins, col = "darkgray", border = "white")
    
  })
  
  output$wordcloud <- renderPlot({

    # generate bins based on input$bins from ui.R
    word <- tolower(input$word)

    # draw the histogram with the specified number of bins
    getTweets(word, 250, 75)
    
    
  })
  
  
  
  output$map <- renderLeaflet({
    
    set.seed(1)
    # generate bins based on input$bins from ui.R
    sub <- sample(seq(nrow(data)), input$n_obs*1000, replace = F)
    sub <- data[sub,]
    choice <- input$opt_choice

    # draw the plot with the specified number of bins
    if (choice == 1) {
      plt <- leaflet() %>%
        setView(lng = coord$lon, lat = coord$lat, zoom = 12) %>%
        addProviderTiles(providers$MtbMap) %>%
        addProviderTiles(providers$Stamen.TonerLines,
                         options = providerTileOptions(opacity = 0.35)) %>%
        addProviderTiles(providers$Stamen.TonerLabels) %>%
        addMarkers(lng = sub$Lon, lat = sub$Lat, label = sub$Base, clusterOptions = markerClusterOptions())
      print(plt)
    } else if (choice == 2) {
      plt <- leaflet() %>%
        setView(lng = coord$lon, lat = coord$lat, zoom = 12) %>%
        addProviderTiles(providers$MtbMap) %>%
        addProviderTiles(providers$Stamen.TonerLines,
                         options = providerTileOptions(opacity = 0.35)) %>%
        addProviderTiles(providers$Stamen.TonerLabels) %>%
        addCircleMarkers(lng = sub$Lon, lat = sub$Lat, color = "red", radius = 3, weight = 1, opacity = 0.5)
      print(plt)
    } #else if (choice == 3) {
    #   plt <- leaflet() %>%
    #     setView(lng = coord$lon, lat = coord$lat, zoom = 12) %>%
    #     addProviderTiles(providers$MtbMap) %>%
    #     addProviderTiles(providers$Stamen.TonerLines,
    #                      options = providerTileOptions(opacity = 0.35)) %>%
    #     addProviderTiles(providers$Stamen.TonerLabels) %>%
    #     addCircleMarkers(lng = sub$Lon, lat = sub$Lat, color = "red", radius = 3, weight = 1, opacity = 0.5)
    #   print(plt)
    # }
    
  })
  
})





