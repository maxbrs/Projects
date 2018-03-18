import sys
from pyspark import SparkContext
sc = SparkContext()

# Lecture d un fichier texte : le fichier est decompose en lignes.
lines = sc.textFile("iliad.mb.txt")
print(lines)
# Decomposition de chaque ligne en mots
words = lines.flatMap(lambda line: line.split(' '))
# Chacun des mots est transforme en une cle-valeur
words_with1 = words.map(lambda word: (word, 1))
# Les valeurs associees a chaques cle sont sommees
word_counts = words_with1.reduceByKey(lambda count1, count2: count1 + count2)
# Le resultat est recupere
result = word_counts.collect()

# Chaque paire (cle, valeur) est affichee
#for (word, count) in result:
#    print(word.encode("utf8"), count)
print("nb mots : " + str(len(result)))
