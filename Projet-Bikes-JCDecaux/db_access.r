debut <- Sys.time()

library(RMySQL)
library(leaflet)
library(ggplot2)
library(ggmap)

setwd("C:/Users/mbriens/Documents/Kaggle/GIT/Kaggle/Projet-Bikes-JCDecaux")
# setwd("C:/Users/mbriens/Documents/Kaggle/GIT/Kaggle/Projet-Bikes-JCDecaux/BikeStations")

#----------------------------------------

############################
#                          #
#   JCDECAUX : BIKES APP   #
#                          #
############################

# Cf. https://www.r-bloggers.com/accessing-mysql-through-r/
# Cf. https://www.statmethods.net/advstats/timeseries.html



#----------
# Connecting database :
#----------

user = 'root'
password = 'admin'
database_name = 'bikestations'
host = 'localhost'
port = 5005

mydb = dbConnect(MySQL(), user=user, password=password, dbname=database_name, host=host, port=port)

# Show tables in database
dbListTables(mydb)

# Show attributes in 'bike'
dbListFields(mydb, 'bike')

# Extract data from SQL query
query = dbSendQuery(mydb, "SELECT * FROM station")
data = fetch(query, n=-1)
print(data)


df = data[data$sta_city == "Toulouse",]

#coord <- geocode("Toulouse")
coord = data.frame(lat = 43.60465, lon = 1.444209)
m <- leaflet(df) %>% setView(lng = coord$lon, lat = coord$lat, zoom = 12)
m <- m %>% addProviderTiles(providers$Stamen, options = providerTileOptions(opacity = 0.25)) %>%
  addProviderTiles(providers$Stamen.TonerLabels) %>%
  addMarkers(~sta_lon, ~sta_lat, label = ~sta_city)#sta_name)
print(m)





query = dbSendQuery(mydb, "SELECT * FROM bike")
data = fetch(query, n=-1)
#print(data)

df = data[data$bik_sta_ID == 12,]

plot(as.Date(df$bik_timestamp), as.integer(df$bik_available))
axis.Date(1, at = df$bik_timestamp, labels = format(df$bik_timestamp,"%b-%d"), las=2)



plot(data$bik_timestamp)







