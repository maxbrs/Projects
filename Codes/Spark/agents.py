from pyspark import SparkContext
spark = SparkContext()

# Get agents.json file
agents = spark.read.json("agents.json")
agents
agents.count()

# Filter french agents
fr_agents = agents.filter(agents.country_name == "France")
fr_agents
fr_agents.count()
agent = fr_agents.first()
agent
print(agent.country_name, agent.id)

# Several operations
agents.filter(agents.country_name == "France").filter(agents.latitude < 0).count()
agents.filter((agents.country_name == "France") & (agents.latitude < 0)).count()
agents.limit(5).show()

# Create a view (Spark-SQL)
agents.createTempView("agents_table") #createOrReplaceTempView()
spark.sql("SELECT * FROM agents_table ORDER BY id DESC LIMIT 10").show()

# Load a DF in memory and convert it in RDD
agents.persist()
agents.rdd.filter(lambda row: row.country_name == "France").count()

# Convert RDD (containing Row) in DF
from pyspark.sql import Row
rdd = sc.parallelize([Row(name="Alice"), Row(name="Bob")])
spark.createDataFrame(rdd)
