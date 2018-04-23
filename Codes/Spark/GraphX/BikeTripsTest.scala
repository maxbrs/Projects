import org.apache.spark.sql.SQLContext
import org.apache.spark._
import org.apache.spark.rdd.RDD 
import org.apache.spark.util.IntParam 
import org.apache.spark.graphx._
import org.apache.spark.graphx.util.GraphGenerators 

val sqlContext = new SQLContext(sc)

val bikeStations = sqlContext.read.format("csv").
    option("header", "true").
    option("inferSchema", "true").
    load("./201508_station_data.csv")
bikeStations.printSchema()

val bikeTrip = sqlContext.read.format("csv").
    option("header", "true").
    option("inferSchema", "true").
    load("./201508_trip_data.csv")
bikeTrip.printSchema()

val stationsData = bikeStations.
    selectExpr("float(station_id) as station_id", "name").
    distinct()

val tripData = bikeTrip.
    join(stationsData, bikeTrip("Start Station") === stationsData("name")).
    withColumnRenamed("station_id", "start_station_id").
    drop("name").
    join(stationsData, bikeTrip("End Station") === stationsData("name")).
    withColumnRenamed("station_id", "end_station_id").
    drop("name")
// tripData.show(10)

var tripVertices: RDD[Edge[Long]] = tripData.
    select("start_station_id", "end_station_id").
    rdd.
    map(x => (x, 1)).
    reduceByKey((a, b) => a + b).
    // distinct().
    map(x => {
        val start = x._1(0).asInstanceOf[Number].longValue
        val end = x._1(1).asInstanceOf[Number].longValue
        Edge(start, end, x._2)
    })
// tripVertices.count()
// tripVertices.foreach(x => println(x))


var stationNodes: RDD[(VertexId, (String, List[Double], Int, String, String))] = 
    bikeStations.
    rdd.
    distinct().
    map(x => {
        val id = x(0).asInstanceOf[Number].longValue
        val name = x(1).asInstanceOf[String]
        val gps = List(x(2).asInstanceOf[Number].doubleValue, x(3).asInstanceOf[Number].doubleValue)
        val dockCount = x(4).asInstanceOf[Number].intValue
        val city = x(5).asInstanceOf[String]
        val date = x(6).asInstanceOf[String]
        (id, (name, gps, dockCount, city, date))
    }).
    sortBy(x => x._1, ascending = true)
// stationNodes.count()
// stationNodes.foreach(x => println(x))

var graph: Graph[(String, List[Double], Int, String, String), Long] = Graph(stationNodes, tripVertices)
graph.cache()



for (triplet <- graph.triplets.collect) {
    println(s"FROM ${triplet.srcAttr._1} TO ${triplet.dstAttr._1} && ... ${triplet.dstAttr._4}")
}

graph.vertices.count // Nodes

graph.edges.count  // Vertices

graph.
vertices.
filter {
    case (id, (name, gps, dockCount, city, date)) => city == "Redwood City"
}.
foreach {
    case (id, (name, gps, dockCount, city, date)) => println(s"City : $city || stop : $name")
}









