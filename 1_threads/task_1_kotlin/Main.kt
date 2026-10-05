import java.util.concurrent.Callable
import java.util.concurrent.Executors

fun main() {
    val tokens = System.`in`.bufferedReader().readText()
        .trim()
        .split(Regex("\\s+"))
        .filter { it.isNotEmpty() }

    if (tokens.isEmpty()) return

    val n = tokens.first().toIntOrNull()
        ?: error("The first value must be the array length")
    require(n > 0) { "The array length must be positive" }
    require(tokens.size >= n + 1) { "Not enough array values" }

    val values = LongArray(n) { index ->
        tokens[index + 1].toLongOrNull()
            ?: error("Array values must be integers")
    }

    val workerCount = minOf(
        n,
        Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
    )
    val executor = Executors.newFixedThreadPool(workerCount)

    try {
        val chunkSize = (n + workerCount - 1) / workerCount
        val tasks = (0 until n step chunkSize).map { start ->
            val end = minOf(start + chunkSize, n)
            Callable { (start until end).sumOf { index -> values[index] } }
        }

        val total = tasks.map { executor.submit(it) }.sumOf { it.get() }
        println(total)
    } finally {
        executor.shutdown()
    }
}
