import java.net.ServerSocket
import java.nio.charset.StandardCharsets
import java.util.concurrent.ConcurrentHashMap

int port = args.length > 0 ? args[0].toInteger() : 4044
def storage = new ConcurrentHashMap<String, String>()
def server = new ServerSocket(port)

println "Storage server is listening on port ${port}"

while (true) {
    def socket = server.accept()
    Thread.start {
        try {
            def reader = new BufferedReader(
                new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8)
            )
            def writer = new PrintWriter(
                new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8),
                true
            )

            String line
            while ((line = reader.readLine()) != null) {
                def parts = line.trim().split(/\s+/, 3)
                def command = parts.length > 0 ? parts[0].toUpperCase() : ""
                String response

                if (command == "PUT") {
                    if (parts.length != 3 || parts[1].isEmpty() || parts[2].isEmpty()) {
                        response = "ERROR expected: PUT key value"
                    } else {
                        def previous = storage.putIfAbsent(parts[1], parts[2])
                        response = previous == null ? "STORED" : "EXISTS"
                    }
                } else if (command == "GET") {
                    if (parts.length != 2) {
                        response = "ERROR expected: GET key"
                    } else {
                        def value = storage.get(parts[1])
                        response = value == null ? "NOT_FOUND" : "VALUE ${value}"
                    }
                } else if (command == "DELETE") {
                    if (parts.length != 2) {
                        response = "ERROR expected: DELETE key"
                    } else {
                        response = storage.remove(parts[1]) == null ? "NOT_FOUND" : "DELETED"
                    }
                } else if (command == "QUIT") {
                    writer.println("BYE")
                    break
                } else {
                    response = "ERROR unknown command"
                }

                writer.println(response)
            }
        } catch (IOException error) {
            System.err.println("Connection error: ${error.message}")
        } finally {
            socket.close()
        }
    }
}
