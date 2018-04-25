# coding: utf-8

import numpy as np
import pandas as pd
import re
import nltk
from nltk.tokenize import word_tokenize, sent_tokenize, PunktSentenceTokenizer
from nltk.corpus import stopwords, state_union
from nltk.stem import PorterStemmer
import gmplot
import gmaps
from gmaps import datasets
import geocoder
from tqdm import tqdm
import matplotlib.pyplot as plt


##########################
#                        #
#          SNCF          #
#   INCIDENTS ANALYSIS   #
#                        #
##########################



#----------
# I. Importation
#----------

df = pd.read_csv("C:/Users/mbriens/Documents/PROJETS/4_SNCF_incidents/data.csv", sep=";", encoding="ansi")

df['ESR'][df['ESR'] == 'oui'] = True
df['ESR'][df['ESR'] == 'non'] = False

df.info()
df.head()



#----------
# II. Text - NLP
#----------

#nltk.download()
line = 14
ex = df['Type'][line]
example = df['Commentaires'][line]

# Split each sentence of the doc
print(sent_tokenize(example, language='french'))
# Split each word of the doc
print(word_tokenize(example))


# Load french stopwords
mots_vides = set(stopwords.words("french"))
print(mots_vides)

# remove stopwords from example sentence
filtered = []
for w in word_tokenize(example):
    if w not in mots_vides:
        filtered.append(w)
print(example)
print(filtered)


# 1. STEMMING (lemmatisation)

ps = PorterStemmer()
ex = ['python', 'pythoner', 'pythoning', 'pythoned', 'pythonly', 'pythonli']

for w in ex:
    print(ps.stem(w))

ex = df['Commentaires'][line]
words = word_tokenize(ex)
for w in words:
    print(ps.stem(w))



tokenized = sent_tokenize(example)


def entites_reco():
    try:
        for i in tokenized[0:5]:
            words = nltk.word_tokenize(i)
            tagged = nltk.pos_tag(words)
            entites = nltk.ne_chunk(tagged)
            entites.draw()
            
            
    except Exception as e:
        print(str(e))

entites_reco()






#----------
# III. Geocode locations
#----------

res=[]
def geocode(num):
    lat = []
    lon = []
    #for i in range(df.shape[1]):
    with tqdm(total = num) as pbar:
        for i in range(num):
            g = geocoder.google(df['Localisation'][i])
            
            city = df['Localisation'][i].lower()
            if re.match(r"(^entre )([a-zéèàêâùïüë \-]*)(( et )|( \& ))([a-z \-]*)$", city) is not None:
                
                res.append(city)
            else:
                res.append(np.nan)
            
            if g.latlng is None :
                
                for nb in range(10):
                    if (nb < 5) and (g.latlng is None):
                        g = geocoder.google(city)
                    elif (nb < 10) and (g.latlng is None):
                        g = geocoder.google(city + ', FRANCE')
                if g.latlng is None:
                    y, x = np.nan, np.nan
            else :
                y, x = (g.latlng)
            lat.append(y)
            lon.append(x)
            pbar.update()
    return lat, lon


num = 100
lat, lon = geocode(num)
lat = pd.DataFrame(lat)
lon = pd.DataFrame(lon)
#res = pd.DataFrame(res)

latlon_df = pd.concat([df['Localisation'][0:num], lon, lat], axis=1)

print(latlon_df.isnull().sum())

latlon_df.columns = ['loc', 'lon', 'lat']

lat2 = [i for i in latlon_df['lat'] if str(i) != 'nan']
lon2 = [i for i in latlon_df['lon'] if str(i) != 'nan']


g = geocoder.google('FRANCE')
centerlat, centerlon = (g.latlng)

gmap = gmplot.GoogleMapPlotter(centerlat, centerlon, 6)
gmap.scatter(lat2, lon2, 'r', marker=False, size=7000)
gmap.draw("test.html")



#s = "Entre Sablé & Avoise"
#s = s.lower()
#regex = r"(^entre )([a-zéèê \-]*)(( et )|( \& ))([a-z \-]*)$"
#res = re.match(regex, s)
#print(res is not None)











