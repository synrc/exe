-module(sh).
-export([ fdlink_executable/0, executable/1, oneliner/1, oneliner/2, sh_loop/2, sh_loop/3, sh_loop/4,
          run/1, run/2, run/3, run/4, run/5 ]). % fold this

fdlink_executable() -> filename:absname(filename:join(code:priv_dir(sh), "fdlink")).
oneliner(C) -> run(C, ignoreeol, ".").
oneliner(C, Cwd) -> run(C, ignoreeol, Cwd).
run(C) -> run(C, binary, ".").
run(C, Log) -> run(C, Log, ".").
executable(C) ->
    case filename:pathtype(C) of
        absolute -> C;
        relative -> case filename:split(C) of
                [C] -> os:find_executable(C);
                _ -> C end;
        _ -> C
    end.

run([C|Args], Log, Cwd) when is_list(C)      -> run(executable(C), Args, Log, Cwd);
run(Command, Log, Cwd) when is_list(Command) -> run(executable("sh"), ["-c", Command], Log, Cwd).

run(Command, Args, ignoreeol, Cwd) ->
    Port = erlang:open_port({spawn_executable, Command},
        [stream, stderr_to_stdout, binary, exit_status,
            {args, Args}, {cd, Cwd}, {line, 16384}]),
    sh_loop(Port, fun({_, Chunk}, Acc) -> [Chunk|Acc] end, []);

run(Command, Args, binary, Cwd) -> run(Command, Args, binary, Cwd, []);

run(Command, Args, Log, Cwd) ->
    {ok, File} = file:open(Log, [append, raw]),
    file:write(File, [">>> ", ts(), " ", Command, " ", [[A, " "] || A <- Args], "\n"]),

    Port = erlang:open_port({spawn_executable, Command},
        [stream, stderr_to_stdout, binary, exit_status,
            {args, Args}, {cd, Cwd}]),

    {done, Status, _} = sh_loop(Port, fun(Chunk, _Acc) -> file:write(File, Chunk), [] end, []),
    file:write(File, [">>> ", ts(), " exit status: ", integer_to_list(Status), "\n"]),
    {done, Status, Log}.

run(Command, Args, _Log, Cwd, Env) ->
    Port = erlang:open_port({spawn_executable, executable(Command)},
        [stream, stderr_to_stdout, binary, exit_status,
            {args, Args}, {cd, Cwd}, {env, Env}]),
    sh_loop(Port, binary).

sh_loop(Port, binary) -> sh_loop(Port, fun(Chunk, Acc) -> [Chunk|Acc] end, []).
sh_loop(Port, Fun, Acc) when is_function(Fun) -> sh_loop(Port, Fun, Acc, fun erlang:iolist_to_binary/1).
sh_loop(Port, Fun, Acc, Flatten) when is_function(Fun) ->
    receive
        {Port, {data, {eol, Line}}} -> sh_loop(Port, Fun, Fun({eol, Line}, Acc), Flatten);
        {Port, {data, {noeol, Line}}} -> sh_loop(Port, Fun, Fun({noeol, Line}, Acc), Flatten);
        {Port, {data, Data}} -> sh_loop(Port, Fun, Fun(Data, Acc), Flatten);
        {Port, {exit_status, Status}} -> {done, Status, Flatten(lists:reverse(Acc))}
    end.

ts() ->
    Ts = {{_Y,_M,_D},{_H,_Min,_S}} = calendar:now_to_datetime(os:timestamp()),
    io_lib:format("~p", [Ts]).
