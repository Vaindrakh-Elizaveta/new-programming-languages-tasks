using Sockets

const PORT = 4042

function calculate(request)
    parts = split(strip(request))
    if length(parts) != 3
        return "ERROR expected: number operation number"
    end

    left = tryparse(Float64, parts[1])
    right = tryparse(Float64, parts[3])
    if left === nothing || right === nothing
        return "ERROR invalid number"
    end

    operation = parts[2]
    if operation == "+"
        result = left + right
    elseif operation == "-"
        result = left - right
    elseif operation == "*"
        result = left * right
    elseif operation == "/"
        if right == 0
            return "ERROR division by zero"
        end
        result = left / right
    else
        return "ERROR unknown operation"
    end

    if !isfinite(result)
        return "ERROR result is not finite"
    end
    return "RESULT $(result)"
end

function handle_client(socket)
    try
        while isopen(socket) && !eof(socket)
            request = readline(socket)
            if uppercase(strip(request)) == "QUIT"
                println(socket, "BYE")
                flush(socket)
                break
            end
            println(socket, calculate(request))
            flush(socket)
        end
    catch error
        if !(error isa EOFError)
            println(stderr, "Connection error: ", error)
        end
    finally
        close(socket)
    end
end

server = listen(ip"0.0.0.0", PORT)
println("Calculator server is listening on port $PORT")

while true
    socket = accept(server)
    @async handle_client(socket)
end
