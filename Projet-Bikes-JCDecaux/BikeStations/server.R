#debut <- Sys.time()

library(shiny)
library(RMySQL)
library(leaflet)
library(ggplot2)
library(ggmap)

# setwd("C:/Users/mbriens/Documents/Kaggle/GIT/Kaggle/Projet-Bikes-JCDecaux")

#----------
# Connecting database :
#----------

user = 'root'
password = 'admin'
database_name = 'BikeStations'
host = 'localhost'
port = 5005

mydb = dbConnect(MySQL(), user=user, password=password, dbname=database_name, host=host, port=port)
query = dbSendQuery(mydb, "SELECT * FROM STATION")
data = fetch(query, n=-1)


list_cities = c("Toulouse", "Dublin", "Lyon", "Nantes", "Marseille", "Stockholm", "Luxembourg")
#list_cities = c('Brisbane', 'Bruxelles-Capitale', 'Namur', 'Santander', 'Seville', 'Valence', 'Amiens', 'Besancon', 'Cergy-Pontoise', 'Creteil', 'Lyon', 'Marseille', 'Mulhouse', 'Nancy', 'Nantes', 'Rouen', 'Toulouse', 'Dublin', 'Toyama', 'Vilnius', 'Luxembourg', 'Lillestrom', 'Kazan', 'Goteborg', 'Lund', 'Stockholm', 'Ljubljana')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  output$map <- renderLeaflet({
    res = as.integer(input$opt_choice)
    city = list_cities[res]
    df = data[data$sta_city == city,]
    #zoom = as.integer(mean(max(df$sta_lat)-min(df$sta_lat), max(df$sta_lon)-min(df$sta_lon))*150)
    coord = data.frame(lat = mean(df$sta_lat), lon = mean(df$sta_lon))
    plt <- leaflet(df) %>% setView(lng = coord$lon, lat = coord$lat, zoom = 12) %>%
      addProviderTiles(providers$Stamen, options = providerTileOptions(opacity = 0.25)) %>%
      addProviderTiles(providers$Stamen.TonerLabels) %>%
      addMarkers(~sta_lon, ~sta_lat, label = ~sta_name)
    print(plt)
  })
  
  observe({
    input$reset_button
    df = data[data$sta_city == list_cities[as.numeric(input$opt_choice)],]
    coord = data.frame(lat = mean(df$sta_lat), lon = mean(df$sta_lon))
    leafletProxy("map") %>% setView(lat = coord$lat, lng = coord$lon, zoom = 12)
  })

})
