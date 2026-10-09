import java.net.Socket
import java.nio.charset.StandardCharsets

String host = args.length > 0 ? args[0] : "127.0.0.1"
int port = args.length > 1 ? args[1].toInteger() : 4044
def socket = new Socket(host, port)

println "Connected to ${host}:${port}"

try {
    def serverReader = new BufferedReader(
        new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8)
    )
    def serverWriter = new PrintWriter(
        new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8),
        true
    )
    def consoleReader = new BufferedReader(
        new InputStreamReader(System.in, StandardCharsets.UTF_8)
    )

    String request
    while ((request = consoleReader.readLine()) != null) {
        serverWriter.println(request)
        println "Server: ${serverReader.readLine()}"
        if (request.trim().equalsIgnoreCase("QUIT")) {
            break
        }
    }
} finally {
    socket.close()
}
