# -*- coding: utf-8 -*-

import pandas
import re
import nltk
nltk.download('punkt')  # separateurs de mots
nltk.download('averaged_perceptron_tagger')  # Pour le POS tagging
nltk.download('maxent_ne_chunker')  # identifier les entités nommées
nltk.download('words')  # Acceder au corpus de mots

def findPhrases(text,l):
    parts = text.split("\n")
    for part in parts:
        for val in re.finditer('[A-Z](\w| |\,)+\.', part):
            if len(val.group(0).split(" "))<10:
                continue
            for country in l:
                if country in val.group(0):
                    print (nltk.ne_chunk(nltk.pos_tag(nltk.word_tokenize(val.group(0)))))
                    break

def main():
    countries = [x.strip() for x in open("listCountries.txt",'r').readlines()]
    df = pandas.DataFrame.from_csv("simplewiki.csv", encoding='utf-8')
    for page in list(df['text']):
        findPhrases(page,countries)

if __name__ == "__main__":
    main()