import scala.io.Source

object Main {
  // Input format: rows columns followed by rows * columns positive costs.
  // Compile: scalac Main.scala
  // Run: scala Main
  def main(args: Array[String]): Unit = {
    val source = Source.fromInputStream(System.in)
    val input = try source.mkString.trim finally source.close()
    if (input.isEmpty) return

    val tokens = input.split("\\s+")
    var position = 0

    def nextInt(description: String): Int = {
      if (position >= tokens.length) {
        throw new IllegalArgumentException(s"Missing $description")
      }
      val value = tokens(position).toInt
      position += 1
      value
    }

    val rowCount = nextInt("row count")
    val columnCount = nextInt("column count")
    require(rowCount > 0 && columnCount > 0, "Table dimensions must be positive")

    val costs = Array.ofDim[Long](rowCount, columnCount)
    for (row <- 0 until rowCount; column <- 0 until columnCount) {
      if (position >= tokens.length) {
        throw new IllegalArgumentException("Not enough cell costs")
      }
      val cost = tokens(position).toLong
      position += 1
      require(cost > 0, "Every cell cost must be positive")
      costs(row)(column) = cost
    }

    val minimumCosts = Array.ofDim[Long](rowCount, columnCount)

    for (row <- 0 until rowCount; column <- 0 until columnCount) {
      if (row == 0 && column == 0) {
        minimumCosts(row)(column) = costs(row)(column)
      } else {
        val fromTop = if (row > 0) minimumCosts(row - 1)(column) else Long.MaxValue
        val fromLeft = if (column > 0) minimumCosts(row)(column - 1) else Long.MaxValue
        minimumCosts(row)(column) = math.min(fromTop, fromLeft) + costs(row)(column)
      }
    }

    println(minimumCosts(rowCount - 1)(columnCount - 1))
  }
}
