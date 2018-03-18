from pyspark.sql import Row
from pyspark.ml.feature import CountVectorizer, StringIndexer
from pyspark.ml.classification import NaiveBayes
from pyspark.ml.evaluation import MulticlassClassificationEvaluator

def load_dataframe(path):
    rdd = sc.textFile(path)\
        .map(lambda line: line.split())\
        .map(lambda words: Row(label=words[0], words=words[1:]))
    return spark.createDataFrame(rdd)

train_data = load_dataframe("20ng-train-all-terms.txt")
test_data = load_dataframe("20ng-test-all-terms.txt")

vectorizer = CountVectorizer(inputCol="words", outputCol="bag_of_words")
vectorizer_transformer = vectorizer.fit(train_data)

train_bag_of_words = vectorizer_transformer.transform(train_data)
test_bag_of_words = vectorizer_transformer.transform(test_data)

train_data.select("label").distinct().sort("label").show(truncate=False)
label_indexer = StringIndexer(inputCol="label", outputCol="label_index")
label_indexer_transformer = label_indexer.fit(train_bag_of_words)

train_bag_of_words = label_indexer_transformer.transform(train_bag_of_words)
test_bag_of_words = label_indexer_transformer.transform(test_bag_of_words)


classifier = NaiveBayes(
    labelCol="label_index", featuresCol="bag_of_words", predictionCol="label_index_predicted"
)
classifier_transformer = classifier.fit(train_bag_of_words)
test_predicted = classifier_transformer.transform(test_bag_of_words)
test_predicted.select("label_index", "label_index_predicted").limit(10).show()

evaluator = MulticlassClassificationEvaluator(labelCol="label_index", predictionCol="label_index_predicted", metricName="accuracy")
accuracy = evaluator.evaluate(test_predicted)
print("Accuracy = {:.2f}".format(accuracy))

#----------

from pyspark.ml import Pipeline
#pipeline = Pipeline([estimator1, estimator2, transformerr1, estimator3, ...])

vectorizer = CountVectorizer(inputCol="words", outputCol="bag_of_words")
label_indexer = StringIndexer(inputCol="label", outputCol="label_index")
classifier = NaiveBayes(
    labelCol="label_index", featuresCol="bag_of_words", predictionCol="label_index_predicted",
)
pipeline = Pipeline(stages=[vectorizer, label_indexer, classifier])
pipeline_model = pipeline.fit(train_data)

test_predicted = pipeline_model.transform(test_data)
