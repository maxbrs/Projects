debut <- Sys.time()

library(plyr)
library(dplyr)
library(ggplot2)
library(ggmap)
library(leaflet)
library(rgdal)
library(rgeos)
library(plotrix)
library(classInt)
library(mapproj)
library(geosphere)
library(corrplot)
# library(RTextTools)
# library(tm)
library(SnowballC)

setwd("C:/Users/mbriens/Documents/PROJETS/4_SNCF_incidents")
load("./.RData")

#----------------------------------------

######################################
#                                    #
#   SNCF : SPATIAL & TEXT ANALYSIS   #
#                                    #
######################################

# Source : https://ressources.data.sncf.com/explore/dataset/incidents-securite/information/
# Fréquentation en gares : https://data.sncf.com/explore/dataset/frequentation-gares/information/
# Référentiel des gares de voyageurs : https://data.sncf.com/explore/dataset/referentiel-gares-voyageurs/information/

# Cf. https://www.sylvaindurand.org/spatial-data-analysis-with-R/
# Cf. https://andrewbtran.github.io/NICAR/2017/maps/mapping-census-data.html


#----------
# Loading and rearrange data :
#----------

df <- read.csv("./data.csv", sep=";", encoding="ansi")

Unaccent <- function(text){
  text <- gsub("['`^~\"]", " ", text)
  text <- iconv(text, to="ASCII//TRANSLIT//IGNORE")
  text <- gsub("['`^~\"]", "", text)
  return(text)
}
df <- df %>% mutate(
  id = as.factor(seq(1, nrow(df))),
  Date = as.Date(Date, "%d/%m/%Y"),
  Localisation = as.character(Unaccent(tolower(as.character(Localisation)))),
  Localisation = as.factor(gsub("-", " ", Localisation)),
  ESR = as.logical(revalue(ESR, c("ND" = NA, "oui" = TRUE, "non" = FALSE))),
  Commentaires = as.character(Commentaires)
)
str(df)



#----------
# Geocode locations :
#----------

# Detect dual locations :
dual_loc <- function(loc){
  loc = as.character(loc)
  re = '(^entre )([a-zéèàêâùïüë[:space:][:punct:]]*)(( et )|( & ))([a-zéèàêâùïüë[:space:][:punct:]]*)'
  match = grep(re, loc, value = F)
  res = NULL
  for(each in loc[match]){
    temp = gsub('(^entre )', '', each)
    temp = strsplit(temp, '(( et )|( & ))')
    temp = unlist(temp)
    res = rbind(res,temp)
  }
  res = as.data.frame(cbind(loc[match],res))
  rownames(res) = match
  colnames(res) = c('original', 'villeA', 'villeB')
  return(res)
}
re = '(^entre )([a-zéèàêâùïüë[:space:][:punct:]]*)(( et )|( & ))([a-zéèàêâùïüë[:space:][:punct:]]*)'
match = grep(re, df$Localisation, value = F)
single = df[-match,]
dual = dual_loc(df$Localisation)
dual = cbind(dual, df[match,])

# Select distinct localisations :
cities = unique(c(as.character(single$Localisation), as.character(dual$villeA), as.character(dual$villeB)))
# cities = unique(c(levels(dual$villeA), levels(dual$villeB)))
cities[cities == 'achere triage   depot'] <- 'achere triage'
cities <- cities[cities != ""]
cities <- unique(as.character(cities))

# Geocode cities to get GPS locations :
geocoding <- function(loc, window = seq(length(loc))){
  geo = NULL
  for(i in window){
    print(i)
    print(loc[i])
    res = geocode(paste(loc[i], ', France'), force = T)
    if(is.na(res[1])){
      nb=0
      while((nb<4) && (is.na(res[1]))){
        if(nb <= 1){
          res = geocode(paste(loc[i], ', France'), force = T)
        } else {
          res = geocode(loc[i], force = T)
        }
        nb = nb+1
      }
    }
    if(is.na(res[1])){
      print("no station")
    }
    geo = rbind(geo, cbind(loc[i], res))
  }
  colnames(geo) = c("ville","lon","lat")
  return(geo)
}

geo = geocoding(cities)#, seq(50,150))
geocodeQueryCheck()
# print(geo)

# Check if GPS localisations seems to be in France :
is_fr <- function(geo){
  resu = NULL
  for(i in seq(nrow(geo))){
    rep = FALSE
    if(is.na(geo[i,'lat']) | is.na(geo[i,'lon'])){
      rep = FALSE
    } else if(((40 <= geo[i,'lat']) & (geo[i,'lat'] <= 55)) & ((-5 <= geo[i,'lon']) & (geo[i,'lon'] <= 10))){
      rep = TRUE
    }
    resu = c(resu, rep)
  }
  return(resu)
}
test = is_fr(geo)
geo[test == F,c('lat','lon')] = c(NA, NA)

# Split dual & unique localisations :
single_geo = merge(single, geo, by.x = "Localisation", by.y = "ville", all.x = T)
single_resu = single_geo[,c('Localisation', 'lat', 'lon', 'Date', 'ESR', 'Type', 'Commentaires', 'id')]
colnames(single_resu) = c('ville', 'lat', 'lon', 'Date', 'ESR', 'Type', 'Commentaires', 'id')

dual_geo = merge(dual, geo, by.x = "villeA", by.y = "ville", all.x = T)

dual_geo = dual_geo[,c("villeA", "villeB", "Date", "Localisation", "ESR", "Type", "Commentaires", "id", "lon", "lat")]
colnames(dual_geo) = c("villeA", "villeB", "Date", "Localisation", "ESR", "Type", "Commentaires", "id", "lonA", "latA")
dual_geo = merge(dual_geo, geo, by.x = "villeB", by.y = "ville", all.x = T)
colnames(dual_geo) = c("villeB", "villeA", "Date", "Localisation", "ESR", "Type", "Commentaires", "id", "lonA", "latA", "lonB", "latB")
dist = NULL
for(i in seq(nrow(dual_geo))){
  dist = c(dist, distm(c(dual_geo$lonA[i], dual_geo$latA[i]), c(dual_geo$lonB[i], dual_geo$latB[i]), fun = distHaversine)/1000)
}
dual_geo = cbind(dual_geo, dist)
ville = NULL
lat = NULL
lon = NULL
dual_geo <- dual_geo %>% mutate(
  Localisation = as.character(Localisation),
  villeA = as.character(villeA),
  villeB = as.character(villeB)
)
for(i in seq(nrow(dual_geo))){
  # IF 'dist' is NA (only one city have been located)
  if(is.na(dual_geo$dist[i])){
    if(is.na(dual_geo$lonB[i])){
      ville = c(ville,dual_geo$villeA[i])
      lat = c(lat,dual_geo$latA[i])
      lon = c(lon,dual_geo$lonA[i])
    } else {
      ville = c(ville,dual_geo$villeB[i])
      lat = c(lat,dual_geo$latB[i])
      lon = c(lon,dual_geo$lonB[i])
    }
  }
  # IF 'dist' is high (not precise enough)
  else if(dual_geo$dist[i] >= 100){
    ville = c(ville,dual_geo$villeA[i])
    lat = c(lat,dual_geo$latA[i])
    lon = c(lon,dual_geo$lonA[i])
  }
  # IF 'dist' is low (get avg of locations)
  else{
    ville = c(ville, dual_geo$Localisation[i])
    lat = c(lat, mean(c(dual_geo$latA[i], dual_geo$latB[i])))
    lon = c(lon, mean(c(dual_geo$lonA[i], dual_geo$lonB[i])))
  }
}
dual_resu = as.data.frame(cbind(ville, lat, lon, dual_geo[,c("Date", "ESR", "Type", "Commentaires", "id")]))
dual_resu <- dual_resu %>% mutate(
  lat = as.numeric(as.character(lat)),
  lon = as.numeric(as.character(lon))
)

# Concatenate resu (single & dual)
df = rbind(single_resu, dual_resu)
df <- df[order(df$id),]



#----------
# Plot locations :
#----------

# coord <- geocode("France")
coord = data.frame(lat = 46.227638, lon = 2.213749)
m <- leaflet(df) %>% setView(lng = coord$lon, lat = coord$lat, zoom = 5)
m <- m %>% addProviderTiles(providers$Stamen, options = providerTileOptions(opacity = 0.25)) %>%
  addProviderTiles(providers$Stamen.TonerLabels) %>%
  addMarkers(~lon, ~lat, label = ~as.character(ville))
print(m)

zone <- readOGR(dsn="C:/Users/mbriens/Documents/PROJETS/4_SNCF_incidents/MAP",  layer="DEPARTEMENT")
proj4string(zone) # Check which projection is used
zone = spTransform(zone, CRS("+proj=longlat +datum=WGS84"))
bound <- readOGR(dsn="C:/Users/mbriens/Documents/PROJETS/4_SNCF_incidents/MAP",  layer="LIMITE_DEPARTEMENT")
bound = spTransform(bound, CRS("+proj=longlat +datum=WGS84"))
bound <- bound[bound$NATURE %in% c('FrontiÃ¨re internationale','Limite cÃ´tiÃ¨re'),]
plot(bound,  col="#FFFFFF")
plot(bound,  col="#D8D6D4", lwd=6, add=TRUE)
plot(zone,col="#FFFFFF", border="#CCCCCC",lwd=.7, add=TRUE)
plot(bound,  col="#666666", lwd=1, add=TRUE)
points(df$lat ~ df$lon, col = "red", cex = 1, pch=20)

nPolys <- sapply(dep@polygons, function(x)length(x@Polygons))
zone <- zone#[which(nPolys==max(nPolys)),]
zone.df <- fortify(zone)
points <- data.frame(long = df$lon, 
                     lat = df$lat,
                     id  = df$ville, stringsAsFactors=F)
ggplot(zone.df, aes(x=long,y=lat,group=group))+
  geom_polygon(fill="lightgreen")+
  geom_path(colour="grey50")+
  geom_point(data=points,aes(x=long,y=lat,group=NULL, color=id), size=4)+
  coord_fixed() +
  theme(legend.position="none")



#----------
# Deduce Department :
#----------

dep = NULL
pb <- txtProgressBar(min = 0, max = length(levels(zone$CODE_DEPT)), style = 3)
for(each in seq(length(levels(zone$CODE_DEPT)))){
  dep_id = levels(zone$CODE_DEPT)[each]
  # print(dep_id)
  departement = zone[zone$CODE_DEPT == dep_id,]
  # print(as.character(departement$NOM_DEPT))
  for(i in seq(nrow(df))){
    if(is.na(df$lat[i]) | is.na(df$lon[i])){
      dep[i] = ""
    } else if(gContains(departement, SpatialPoints(df[i,c("lon","lat")],proj4string=CRS(proj4string(departement))))){
      dep[i] = as.character(departement$CODE_DEPT)
    }
  }
  setTxtProgressBar(pb, each)
}
dep[dep == ""] = NA

df_dep = cbind(df,dep)
View(head(df_dep, 10))



#----------
# Get traffic ammount, from SNCF open data :
#----------

traffic <- read.csv("./frequentation-gares.csv", sep=";", encoding="utf-8")
traffic = traffic[,c("Code.postal", "voyageurs.2016", "voyageurs.2015", "voyageurs.2014")]
traffic$freq_moy = (apply(traffic[,c("voyageurs.2016", "voyageurs.2015", "voyageurs.2014")], 1, mean, na.rm = T))

dep = NULL
for(i in seq(length(traffic$Code.postal))){
  loc = traffic$Code.postal[i]
  if(is.na(loc)){
    dep[i] = NA
  } else if(nchar(loc) == 5){
    dep[i] = substr(loc, start=1, stop=2)
  } else if(nchar(loc) == 4){
    dep[i] = paste(0,substr(loc, start=1, stop=1), sep="")
  } else {
    print('error')
  }
}
traffic$dep = dep
print(prop.table(table(is.na(traffic$dep)))*100)
nb_gares = data.frame(table(traffic$dep))
colnames(nb_gares) = c("dep", "nb_gares")
traffic = aggregate(freq_moy ~ dep, traffic, sum)
traffic = merge(traffic, nb_gares, by = "dep", all.x = T)
colnames(traffic) = c("dep", "nb_usagers", "nb_gares")



#----------
# Build ANALYZE table :
#----------

analyse = data.frame(table(df_dep$dep))
colnames(analyse) = c("dep", "nb_incidents")
analyse = merge(analyse, traffic, by = "dep", all.x = T)
esr = aggregate(ESR ~ dep, df_dep, sum)
analyse = merge(analyse, esr, by = "dep", all.x = T)
type_concat = aggregate(as.character(Type) ~ dep, df_dep, paste, collapse = " | ")
colnames(type_concat) = c("dep", "concat_type")
analyse = merge(analyse, type_concat, by = "dep", all.x = T)
comment_concat = aggregate(as.character(Commentaires) ~ dep, df_dep, paste, collapse = " | ")
colnames(comment_concat) = c("dep", "concat_comment")
analyse = merge(analyse, comment_concat, by = "dep", all.x = T)
# sum(analyse$nb_incidents)



#----------
# Firsts analysis :
#----------

plot(x=analyse$nb_usagers, y=analyse$nb_incidents, log="xy")
plot(x=analyse$nb_gares, y=analyse$nb_incidents, log="xy")

corr = cor(analyse[,c("nb_incidents", "nb_gares", "nb_usagers")], use = "complete.obs", method="pearson")
diag(corr) = NA
corrplot(corr, type = "upper", order = "hclust", na.label = "o")

reg = lm(nb_incidents ~ nb_gares + nb_usagers, data = analyse)
TV = var(analyse$nb_incidents)
RV = var(reg$residuals)
PEV = 100*(TV-RV)/TV
summary(reg)
print(paste('Percentage of explained variation =', round(PEV, 4), '%'))

colnames(zone@data)[2] = "dep"
zone@data$id <- rownames(zone@data)
zone@data <- join(zone@data, analyse, by="dep")
zone.df <- fortify(zone)
zone.df <- join(zone.df, zone@data, by="id")
points <- data.frame(long = df$lon, 
                     lat = df$lat,
                     id  = df$ville, stringsAsFactors=F)
ggplot(zone.df, aes(x=long,y=lat,group=group)) +
  geom_polygon(aes(fill=nb_incidents/nb_usagers), color = "white") +
  geom_point(data=points, aes(x=long, y=lat, group=NULL), colour="#000000", alpha = 0.075, size = 1) +
  scale_fill_gradientn(colours = rev(rainbow(2)), trans = "log10") +
# geom_text(data=points, aes(x=long, y=lat, group=NULL, color="black", label=id)) +
  coord_fixed() #+
  # theme(legend.position="none")
  







#----------
# Text analysis :
#----------

# concat_type, concat_comment
library(tidytext)
library(tm)
corp <- data.frame(id=seq(nrow(analyse)), words=as.character(analyse$concat_type))
corp$words = as.character(corp$words)
Encoding(corp$words) = "latin"
# corp$words = stringr::str_replace_all(corp$words, "’", " ")
corp <- Corpus(VectorSource(corp$words))#, encoding = "utf-8")
toSpace <- content_transformer(function(x, pattern) gsub(pattern, " ", x))
corp <- tm_map(corp, toSpace, "/")
corp <- tm_map(corp, toSpace, "@")
corp <- tm_map(corp, content_transformer(tolower))
corp <- tm_map(corp, content_transformer(removeNumbers))
corp <- tm_map(corp, removePunctuation)
corp <- tm_map(corp, stripWhitespace)
stopwords = c("au","aux","avec","ce","ces","dans","de","des","du","elle","en","et","eux","il","je","la","le","leur","lui","ma","mais","me","même","mes","moi","mon","ne","nos","notre","nous","on","ou","par","pas","pour","qu","que","qui","sa","se","ses","son","sur","ta","te","tes","toi","ton","tu","un","une","vos","votre","vous","c","d","j","l","à","m","n","s","t","y","été","étée","étées","étés","étant","suis","es","est","sommes","êtes","sont","serai","seras","sera","serons","serez","seront","serais","serait","serions","seriez","seraient","étais","était","étions","étiez","étaient","fus","fut","fûmes","fûtes","furent","sois","soit","soyons","soyez","soient","fusse","fusses","fût","fussions","fussiez","fussent","ayant","eu","eue","eues","eus","ai","as","avons","avez","ont","aurai","auras","aura","aurons","aurez","auront","aurais","aurait","aurions","auriez","auraient","avais","avait","avions","aviez","avaient","eut","eûmes","eûtes","eurent","aie","aies","ait","ayons","ayez","aient","eusse","eusses","eût","eussions","eussiez","eussent","ceci","cela","celà","cet","cette","ici","ils","les","leurs","quel","quels","quelle","quelles","sans","soi","sur","entre","non","tout")
corp <- tm_map(corp, removeWords, stopwords)

#corp <- tm_map(corp, stemDocument, language="french")

mTD <- TermDocumentMatrix(corp)#, control=list(stemming=TRUE))
mTD = removeSparseTerms(mTD, 0.95)
mTD = as.matrix(mTD)
mDT = t(mTD)
colnames(mDT)







tf <- mDT
idf <- log(nrow(mDT)/colSums(mDT))
tfidf <- mDT
for(word in names(idf)){
  tfidf[,word] <- tf[,word] * idf[word]
}


test = colSums(tfidf)
head(sort(test, decreasing = T))























