# -*- coding: utf-8 -*-

import pandas
import re
import nltk

nltk.download('punkt')  # separateurs de mots
nltk.download('averaged_perceptron_tagger')  # Pour le POS tagging
nltk.download('maxent_ne_chunker')  # identifier les entités nommées
nltk.download('words')  # Acceder au corpus de mots
print("1",nltk.ne_chunk(nltk.pos_tag(nltk.word_tokenize("May has also dealt with the war in Iraq and Syria."))))
print("2",nltk.ne_chunk(nltk.pos_tag("May has also dealt with the war in Iraq and Syria.".split())))
#print("3",nltk.ne_chunk(nltk.word_tokenize("May has also dealt with the war in Iraq and Syria.")))

#1) La première ligne ne fonctionne pas parce qu'il manquait des dépendences, la librairie nltk en l'occurence
#2) Au lieu d'utiliser tokenisation de nltk, la deuxième ligne utise un split simple, d'où le fait que le
# tokenizer ai identifié le point comme un carcatère à part, à la différence du split simple
#3) ne_chunk cherche des entités nommées taggées, donc sans le pos-tag ça ne marche pas!
#4) ne_chunk utilise le chunker de NLTK pour trier une liste de mots taggés, càd celui qui maximise l'entropie
#5)Cas d'erreur de ne_chunk:
#       (PERSON Kyung/NNP Hee/NNP University/NNP)
#       (ORGANIZATION Rio/NNP) de/IN (PERSON Janeiro/NNP)
#       (GPE Evanescence/NNP)
#       (PERSON Stone/NNP Sour/NNP)
#       (GPE Francis/NNP)
#       (GPE Jewish/JJ)
#       (PERSON Mexico/NNP State/NNP)

#6)
import sys

from collections import defaultdict

def cleanAndSave(text):
    stdout_ = sys.stdout
    sys.stdout = open("question6country.txt",'w')
    print(text)
    sys.stdout = stdout_

def cleanAndSave2(text):
    stdout_ = sys.stdout
    sys.stdout = open("question6person.txt",'w')
    print(text)
    sys.stdout = stdout_

def dicStats(dic):
    tot = 0
    for k in dic.keys():
        tot+=dic[k]
    temp = sorted(dic.values())
    topten = []
    newdic = {}
    for i in range(min(10,len(temp))):
        newdic[list(dic.keys())[list(dic.values()).index(temp[-i])]] = 100*temp[-i]/tot
    return newdic



def question6():
    df = pandas.DataFrame.from_csv("simplewiki.csv", encoding='utf-8')


    cc = ["France", "United States", "Israel","Colombia"]
    country_dic = defaultdict(int)
    for c in cc:
        cleanAndSave(nltk.ne_chunk(nltk.pos_tag(nltk.word_tokenize(df['text'][df['title'] == c].item()))))
        countries = open("question6country.txt", "r")

        for values in countries.readlines():
            for val in re.finditer("\([A-Z]+ ([A-Za-z]+\/[A-Z]{2,3} ?)+\)", values):
                country_dic[val.group(0).split()[0][1:]] += 1

    pp = ["Shakira", "Gustave Eiffel", "Barack Obama", "Brad Pitt"]
    people_dic = defaultdict(int)
    for p in pp:
        cleanAndSave2(nltk.ne_chunk(nltk.pos_tag(nltk.word_tokenize(df['text'][df['title'] == p].item()))))
        people = open("question6person.txt", "r")

        for values in people.readlines():
            for val in re.finditer("\([A-Z]+ ([A-Za-z]+\/[A-Z]{2,3} ?)+\)", values):
                people_dic[val.group(0).split()[0][1:]] += 1


    print("countries:(percentages)",dicStats(country_dic))
    print("people:(percentages)",dicStats(people_dic))


question6()

