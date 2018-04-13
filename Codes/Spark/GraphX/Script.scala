import org.apache.spark._
import org.apache.spark.rdd.RDD 
import org.apache.spark.util.IntParam 
import org.apache.spark.graphx._
import org.apache.spark.graphx.util.GraphGenerators 

var nodeArray: Array[(Long, (String, Int))] = Array(
    (1, ("Alice", 28)),
    (2, ("Bob", 27)),
    (3, ("Charlie", 65)),
    (4, ("David", 42)),
    (5, ("Ed", 55)),
    (6, ("Fran", 50))
)
var verticeArray: Array[Edge[Int]] = Array(
    Edge(2, 1, 7),
    Edge(2, 4, 2),
    Edge(3, 2, 4),
    Edge(3, 6, 3),
    Edge(4, 1, 1),
    Edge(5, 2, 2),
    Edge(5, 3, 8),
    Edge(5, 6, 3)
)

var nodeRDD: RDD[(Long, (String, Int))] = sc.parallelize(nodeArray)
var verticeRDD: RDD[Edge[Int]] = sc.parallelize(verticeArray)
var graph: Graph[(String, Int), Int] = Graph(nodeRDD, verticeRDD)
graph.cache()

graph
.vertices
.filter { case (id, (name, age)) => age > 30 }
.collect
.foreach { case (id, (name, age)) => println(s"$name is $age")}

for (triplet <- graph.triplets.collect) {
    println(s"${triplet.srcAttr._1} likes ${triplet.dstAttr._1}")
}



