// https://rosettacode.org/wiki/Levenshtein_distance#Scala

import scala.math._

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

val stationsData = bikeStations.
    selectExpr("int(station_id) as station_id", "name", "landmark").
    distinct()
stationsData.printSchema()

// Levenshtein distance function :
def distance(s1:String, s2:String) = {
    val dist=Array.tabulate(s2.length+1, s1.length+1){(j,i)=>if(j==0) i else if (i==0) j else 0}
    for(j<-1 to s2.length; i<-1 to s1.length)
        dist(j)(i)=if(s2(j-1)==s1(i-1)) dist(j-1)(i-1)
            else min(min(dist(j-1)(i)+1, dist(j)(i-1)+1), dist(j-1)(i-1)+1)
    dist(s2.length)(s1.length)
}
println("kitten -> sitting : " + distance("kitten", "sitting"))
println("rosettacode -> raisethysword : " + distance("rosettacode", "raisethysword"))

var nameSimilarity = stationsData.
    crossJoin(
        stationsData
    ).
    map(x => {
        val id1 = x.getInt(0)
        val id2 = x.getInt(3)
        val name1 = (x.getString(1) + " (" + x.getString(2) + ")")
        val name2 = (x.getString(4) + " (" + x.getString(5) + ")")
        val dist = distance(name1, name2)
        // println("BETWEEN " + name1 + " & " + name2 + " = " + dist)
        (id1, name1, id2, name2, dist)
    }).
    toDF("id1", "name1", "id2", "name2", "sim")
nameSimilarity.show()

var simArrays: RDD[Edge[Long]] = nameSimilarity.
    rdd.
    map(x => {
        val start = x.getInt(0)
        val end = x.getInt(2)
        val sim = x.getInt(4)
        Edge(start, end, sim)
    })
// simArrays.count()
// simArrays.foreach(x => println(x))


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

var graph: Graph[(String, List[Double], Int, String, String), Long] = Graph(stationNodes, simArrays)
graph.cache()



for (triplet <- graph.triplets.collect) {
    println(s"SIMILARITY BETWEEN ${triplet.srcAttr._1} AND ${triplet.dstAttr._1} = ${triplet.attr}")
}

graph.vertices.count // Nodes
graph.edges.count  // Arrays
