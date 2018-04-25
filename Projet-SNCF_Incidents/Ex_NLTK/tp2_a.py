# -*- coding: utf-8 -*-

import pandas
import re
import nltk

def cleanAndSave(text):
    f = open("listCountries.txt",'a+')
    for val in re.finditer('\[\[[A-Z](\w| )+\]\]', text):
        val = val.group(0)
        f.write(val[2:-2]+"\n")
    f.close()

def main():
    pages_to_show = ['List of countries']
    df = pandas.DataFrame.from_csv("simplewiki.csv", encoding='utf-8')
    for page in pages_to_show:
        cleanAndSave(df['text'][df['title'] == page].item())

if __name__ == "__main__":
    main()