debut <- Sys.time()

library(plyr)
library(dplyr)
library(ggplot2)
library(ggmap)
library(leaflet)
library(htmltools)
library(tm)
library(RTextTools)
library(SnowballC)
library(caTools)
library(descr)
# library(sentiment)
library(wordcloud)
library(RColorBrewer)
library(reshape2)
library(igraph)


setwd("C:/Users/mbriens/Documents/PROJETS/4_SNCF_incidents")

#----------------------------------------

#################################
#                               #
#   SNCF : SENTIMENT ANALYSIS   #
#                                #
#################################

# Source : https://ressources.data.sncf.com/explore/dataset/incidents-securite/information/?sort=date

# Cf. https://sites.google.com/site/miningtwitter/questions/sentiment/sentiment
# Cf. https://eight2late.wordpress.com/2015/05/27/a-gentle-introduction-to-text-mining-using-r/


#----------
# Loading and rearrange data :
#----------

df <- read.csv("./data.csv", sep=";", encoding="ansi")

df$ESR[df$ESR == "ND"] = NA
Unaccent <- function(text){
  text <- gsub("['`^~\"]", " ", text)
  text <- iconv(text, to="ASCII//TRANSLIT//IGNORE")
  text <- gsub("['`^~\"]", "", text)
  return(text)
}

df$Localisation <- as.character(df$Localisation)
df


df <- df %>% mutate(
  id = seq(1, nrow(df)),
  Date = as.Date(Date, "%d/%m/%Y"),
  Localisation = as.factor(Unaccent(tolower(as.character(Localisation)))),
  ESR = as.logical(revalue(ESR, c("ND" = NA, "oui" = TRUE, "non" = FALSE))),
  Commentaires = as.character(Commentaires)
)

str(df)



#----------
# Geocoding locations :
#----------

# Extract dual-locations :
re = '(^entre )([a-zéèàêâùïüë +.-]*)(( et )|( & ))([a-zéèàêâùïüë +.-]*)$'
match = grep(re, levels(df$Localisation), value = F)
#print(levels(df$Localisation)[match])

dual_loc <- function(){
  res = NULL
  for(loc in levels(df$Localisation)[match]){
    temp = gsub('(^entre )', '', loc)
    temp = strsplit(temp, '(( et )|( & ))')
    temp = unlist(temp)
    res = rbind(res,temp)
  }
  res = as.data.frame(cbind(levels(df$Localisation)[match],res))
  colnames(res) = c('original', 'villeA', 'villeB')
  rownames(res) = match
  return(res)
}

dual = dual_loc()
View(dual)







villes = levels(df$Localisation)[-match]
geo = NULL
for(i in seq(length(villes[1:300]))){
  print(i)
  print(villes[i])
  res = geocode(villes[i])
  if(is.na(res)){
    nb=0
    while((nb<6) && (is.na(res))){
      if(nb < 3){
        res = geocode(villes[i])
      } else {
        res = geocode(paste(villes[i], ', France'))
      }
      nb = nb+1
    }
  }
  if(is.na(res)){
    print("no station")
  }
  geo = rbind(geo, cbind(villes[i], res))
}
colnames(geo) = c("ville","lon","lat")
print(geo)

pos = geo[!(is.na(geo$lon)),]
pos$ville <- as.character(pos$ville)




coord <- geocode("France")
print(pos)
map1 <- get_map(location=c(lon=coord$lon,lat=coord$lat+0.02),zoom=3, source = "stamen", maptype = "toner-lite")
map2 <- get_map(location=c(lon=coord$lon,lat=coord$lat+0.02),zoom=5, source = "stamen", maptype = "toner-lite")
# save(map1, file="~/Kaggle/UBER_NYC/data/map1.rda")
# save(map2, file="~/Kaggle/UBER_NYC/data/map2.rda")
#load("~/Kaggle/UBER_NYC/data/map1.rda")
#load("~/Kaggle/UBER_NYC/data/map2.rda")
#ls()

# 1st mapping : large view, all NYC & surroundings (with airports)
plt_map1 <- ggmap(map2, extent = "device") +
  geom_jitter(data = pos, aes(x=lon, y=lat), alpha=0.6, size = 4, color = "red") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0.1, 0.4), guide = FALSE)
print(plt_map1)

plt_map2 <- ggmap(map2, extent = "device") +
  stat_density2d(data = pos, aes(x = lon, y = lat, fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 100, geom = "polygon") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0.1, 0.3), guide = FALSE)
print(plt_map2)


m <- leaflet(pos) %>% setView(lng = coord$lon, lat = coord$lat, zoom = 4)
m <- m %>% addProviderTiles(providers$Stamen,
                   options = providerTileOptions(opacity = 0.25)) %>%
  addProviderTiles(providers$Stamen.TonerLabels)
m %>% addMarkers(~lon, ~lat, label = ~as.character(ville))

# m %>% addMarkers(~lon, ~lat, popup = ~htmlEscape(as.character(ville)))








#----------
# Text-analysis :
#----------


split <- sample.split(df$id, SplitRatio = 0.8)
train <- subset(df, split == T)
test <- subset(df, split == F)

size = nrow(train)
sep = round(0.8*nrow(train))
sep1 = sep + 1





corpus <- Corpus(VectorSource(df$Commentaires))

toSpace <- content_transformer(function(x, pattern) gsub(pattern, " ", x))
corpus <- tm_map(corpus, toSpace, "/")
corpus <- tm_map(corpus, toSpace, "@")

corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, content_transformer(removeNumbers))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, stripWhitespace)
# stopwords = stopwords("french")
stopwords = c("au","aux","avec","ce","ces","dans","de","des","du","elle","en","et","eux","il","je","la","le","leur","lui","ma","mais","me","même","mes","moi","mon","ne","nos","notre","nous","on","ou","par","pas","pour","qu","que","qui","sa","se","ses","son","sur","ta","te","tes","toi","ton","tu","un","une","vos","votre","vous","c","d","j","l","à","m","n","s","t","y","été","étée","étées","étés","étant","suis","es","est","sommes","êtes","sont","serai","seras","sera","serons","serez","seront","serais","serait","serions","seriez","seraient","étais","était","étions","étiez","étaient","fus","fut","fûmes","fûtes","furent","sois","soit","soyons","soyez","soient","fusse","fusses","fût","fussions","fussiez","fussent","ayant","eu","eue","eues","eus","ai","as","avons","avez","ont","aurai","auras","aura","aurons","aurez","auront","aurais","aurait","aurions","auriez","auraient","avais","avait","avions","aviez","avaient","eut","eûmes","eûtes","eurent","aie","aies","ait","ayons","ayez","aient","eusse","eusses","eût","eussions","eussiez","eussent","ceci","cela","celà","cet","cette","ici","ils","les","leurs","quel","quels","quelle","quelles","sans","soi")
corpus <- tm_map(corpus, removeWords, stopwords)

mTD <- as.matrix(TermDocumentMatrix(corpus,
                                    control = list(removeNumbers = TRUE,
                                                   stopwords = TRUE,
                                                   stemming = FALSE)))
colnames(mTD) <- df$id

FreqMat <- data.frame(ST = rownames(mTD), 
                      Freq = rowSums(mTD), 
                      row.names = NULL)
seuil = round(nrow(df)*0.05)
FreqMat <- FreqMat[FreqMat$Freq > seuil,]
FreqMat <- FreqMat[order(FreqMat$Freq, decreasing = T),]
rownames(FreqMat) = NULL
head(FreqMat, 20)
nrow(FreqMat)

mTD <- mTD[rownames(mTD) %in% FreqMat$ST,]
nrow(mTD)

mDT <- t(mTD)
colnames(mDT) <- rownames(mTD)
rownames(mDT) <- colnames(mTD)


# Plot wordcloud :

set.seed(123)
wordcloud(words = FreqMat$ST, freq = FreqMat$Freq, min.freq = 1,
          max.words=125, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))




my.df.scale <- scale(mTD)
d <- dist(my.df.scale,method="euclidean")
fit <- hclust(d, method="ward.D2")
# plot(fit)
# abline(a=0, b=seq(0,1))

k <- round(nrow(my.df.scale)*0.9)
print(k)

inertie <- sort(fit$height, decreasing = T)
plot(inertie[1:nrow(my.df.scale)], type = "s", xlab = "Nombre de classes", ylab = "Inertie")
points(c(25, 50, k), inertie[c(25, 50, k)], col = c("green3", "red3", "blue3"), cex = 2, lwd = 3)

plot(fit, main = "Partition en 25, 50 ou 90% classes", xlab = "", ylab = "", sub = "", axes = F, hang = -1)
rect.hclust(fit, 25, border = "green3")
rect.hclust(fit, 50, border = "red3")
rect.hclust(fit, k, border = "blue3")

res <- as.data.frame(table(cutree(fit, k = k)))
res <- res[order(as.numeric(as.character(res$Freq)), decreasing = T),]


cosine <- as.matrix(mTD, dimnames = NULL) %*% as.matrix(mDT, dimnames = NULL) /(sqrt(rowSums(mTD^2) %*% t(rowSums(mTD^2))))
#View(cosine)

# cosine <- as.matrix(cosine[seq(30),seq(30)])
# diag(cosine) = 1*10^(-10)
cosine[lower.tri(cosine)] <- NA
df_cosine <- melt(cosine)

df_cosine <- df_cosine[!is.na(df_cosine$value),]
df_cosine <- df_cosine[order(-df_cosine$value),]
df_cosine <- df_cosine[!(df_cosine[,1] == df_cosine[,2]),]
rownames(df_cosine) <- NULL
# df_cosine <- head(df_cosine,225)
df_cosine_graph <- df_cosine[df_cosine$value >= 0.45,]

net <- graph.data.frame(df_cosine_graph, directed = F)
E(net)$weight <- df_cosine_graph$value - 0.4
E(net)$width <- exp(E(net)$weight*5)
V(net)$size <- 5

plot(net, vertex.label.color="black", vertex.label.dist=1)

print(paste('Cosine similarity between \'géometrie\' & \'défaut\' =', round(cosine['géométrie','défaut'] * 100,4), '%'))
print(paste('Cosine similarity between \'porte\' & \'ouverte\' =', round(cosine['porte','ouverte'] * 100,4), '%'))






m <- mDT
m = data.frame(as.matrix(m))
colnames(m)

# Initialisation de la table
table = data.frame(num_variable=integer(),nom_variable=character(),
                   y_false=integer(),y_true=integer(),f_false=integer(),f_true=integer(),
                   chisq1=numeric(),chisq2=numeric(),chisq3=numeric())

var_cible = df$ESR

for (i in seq(1, length(m))){
  #Numéro itération
  print(paste("Itération n°", i, "/",length(m)))
  num_variable = data.frame(i)
  
  #Nom de la variable qui est croisée avec le succès
  nom_variable = data.frame(colnames(m)[i])
  #print(nom_variable)
  
  #Proc Freq
  freq = CrossTable(m[,i]>0, as.factor(as.numeric(var_cible)), chisq = T, prop.chisq = F)
  
  #Sortie 1 : comptage
  sortie1=data.frame(freq$t)
  y_false=subset(sortie1,x=='FALSE' & y=='1')
  y_true=subset(sortie1,x=='TRUE' & y=='1')
  f_false=subset(sortie1,x=='FALSE' & y=='0')
  f_true=subset(sortie1,x=='TRUE' & y=='0')
  
  #Chisq
  chisq1=data.frame(freq$chisq[1])
  chisq2=data.frame(freq$chisq[2])
  chisq3=data.frame(freq$chisq[3])
  
  chisq1=data.frame(freq$CST$statistic)
  chisq2=data.frame(freq$CST$parameter)
  chisq3=data.frame(freq$CST$p.value)
  
  #Ajout des statistiques dans une table
  ligne=cbind(num_variable,nom_variable,y_false[3],y_true[3],f_false[3],f_true[3],chisq1,chisq2,chisq3)
  table=rbind(table,ligne)
}



# On renomme les colonnes
names(table) = c("Num_variable","Nom_variable","NB_success_FALSE","NB_success_TRUE","NB_nonsuccess_FALSE","NB_nonsuccess_TRUE","Chi2","DF","Pvalue")
table <- table[order(table$Pvalue),]
rownames(table) <- NULL
head(table)

res_clust <- as.data.frame(cutree(fit, k = k))
res_clust <- as.data.frame(cbind(word = rownames(res_clust), res_clust))
colnames(res_clust) <- c("word","cluster")
res_clust <- res_clust[order(res_clust$cluster),]
rownames(res_clust) <- NULL

res_nb_clust <- as.data.frame(table(cutree(fit, k=k)))
res_nb_clust$Var1 <- as.numeric(as.character(res_nb_clust$Var1))

res_test <- cbind(as.character(table[,2]), table$Pvalue)
colnames(res_test) <- c("word","Pval")

resu <- merge(x = res_test, y = res_clust, by = "word", all=T)
resu <- merge(x = resu, y = res_nb_clust, by.x = "cluster", by.y = "Var1", all.x = T)
resu <- resu[,c("word", "Pval", "cluster", "Freq")]
resu <- resu[order(resu$Pval),]
rownames(resu) <- NULL

head(resu,20)



word = 'défaut'

FreqMat[FreqMat$ST == word,]
#table(df$ESR[word %in% strsplit(df$Commentaires, ' '))])



head(sort(table(df$Localisation), decreasing = T), 15)
barplot(sort(table(df$Localisation), decreasing = T)[0:30])

df$Commentaires[df$Localisation == "rennes"]


df["sal" %in% df$Commentaires,]
min(df$Date)
max(df$Date)


plot(ts(table(df$Date), start=min(df$Date), end=max(df$Date)))









