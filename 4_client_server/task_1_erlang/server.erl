-module(server).
-export([start/0, start/1]).

start() ->
    start(4041).

start(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [
        binary,
        {packet, line},
        {active, false},
        {reuseaddr, true}
    ]),
    io:format("Echo server is listening on port ~p~n", [Port]),
    accept_loop(ListenSocket).

accept_loop(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
    ClientProcess = spawn(fun() -> wait_for_socket() end),
    ok = gen_tcp:controlling_process(Socket, ClientProcess),
    ClientProcess ! {socket, Socket},
    accept_loop(ListenSocket).

wait_for_socket() ->
    receive
        {socket, Socket} -> client_loop(Socket)
    end.

client_loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            case string:uppercase(string:trim(binary_to_list(Data))) of
                "QUIT" ->
                    gen_tcp:send(Socket, <<"BYE\n">>),
                    gen_tcp:close(Socket);
                _ ->
                    gen_tcp:send(Socket, Data),
                    client_loop(Socket)
            end;
        {error, closed} ->
            ok;
        {error, Reason} ->
            io:format("Connection error: ~p~n", [Reason]),
            gen_tcp:close(Socket)
    end.
