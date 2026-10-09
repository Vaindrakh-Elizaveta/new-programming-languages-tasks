using Sockets

host = length(ARGS) >= 1 ? ARGS[1] : "127.0.0.1"
port = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 4042
socket = connect(host, port)

println("Connected to $host:$port")

try
    while !eof(stdin)
        print("> ")
        flush(stdout)
        request = readline()
        println(socket, request)
        flush(socket)
        println("Server: ", readline(socket))
        if uppercase(strip(request)) == "QUIT"
            break
        end
    end
finally
    close(socket)
end
