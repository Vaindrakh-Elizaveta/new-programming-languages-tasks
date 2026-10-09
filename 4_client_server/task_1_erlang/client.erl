-module(client).
-export([start/0, start/2]).

start() ->
    start("127.0.0.1", 4041).

start(Host, Port) ->
    case gen_tcp:connect(Host, Port, [binary, {packet, line}, {active, false}]) of
        {ok, Socket} ->
            io:format("Connected to ~s:~p~n", [Host, Port]),
            input_loop(Socket);
        {error, Reason} ->
            io:format("Connection failed: ~p~n", [Reason])
    end.

input_loop(Socket) ->
    case io:get_line("> ") of
        eof ->
            gen_tcp:close(Socket);
        Line ->
            ok = gen_tcp:send(Socket, Line),
            case gen_tcp:recv(Socket, 0) of
                {ok, Response} ->
                    io:format("Server: ~ts", [Response]),
                    case string:uppercase(string:trim(Line)) of
                        "QUIT" -> gen_tcp:close(Socket);
                        _ -> input_loop(Socket)
                    end;
                {error, Reason} ->
                    io:format("Connection error: ~p~n", [Reason]),
                    gen_tcp:close(Socket)
            end
    end.
