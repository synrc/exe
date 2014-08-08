-module(sh).
-compile(export_all).

fdlink_executable() -> filename:join(code:priv_dir(sh), "fdlink").
oneliner(C) -> run(C, ignoreeol, ".").
oneliner(C, Cwd) -> run(C, ignoreeol, Cwd).
run(C) -> run(C, binary, ".").
run(C, Log) -> run(C, Log, ".").
executable(C) -> 
    case filename:pathtype(C) of
        absolute -> C;
        relative -> case filename:split(C) of
                [C] -> os:find_executable(C);
                _ -> C % smth like deps/sh/priv/fdlink
            end;
        _ -> C
    end.

run([C|Args], Log, Cwd) when is_list(C) ->
    Executable = executable(C),
    run(Executable, Args, Log, Cwd);

run(Command, Log, Cwd) when is_list(Command) -> run("/bin/sh", ["-c", Command], Log, Cwd).

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

run(Command, Args, binary, Cwd, Env) ->
<<<<<<< HEAD
    Port = erlang:open_port({spawn_executable, Command},
        [stream, stderr_to_stdout, binary, exit_status,
            {args, Args}, {cd, Cwd}, {env, Env}]),
    sh_loop(Port, binary);
=======
    Port = erlang:open_port({spawn_executable, executable(Command)},
        [stream, stderr_to_stdout, binary, exit_status,
            {args, Args}, {cd, Cwd}, {env, Env}]),
    sh_loop(Port, binary).
>>>>>>> 4440828d0189801234ed50479ba3ceb288a2a193

%
% private functions
%

sh_loop(Port, binary) -> sh_loop(Port, fun(Chunk, Acc) -> [Chunk|Acc] end, []).
sh_loop(Port, Fun, Acc) when is_function(Fun) -> sh_loop(Port, Fun, Acc, fun erlang:iolist_to_binary/1).
sh_loop(Port, Fun, Acc, Flatten) when is_function(Fun) ->
    receive
        {Port, {data, {eol, Line}}} ->
            sh_loop(Port, Fun, Fun({eol, Line}, Acc), Flatten);
        {Port, {data, {noeol, Line}}} ->
            sh_loop(Port, Fun, Fun({noeol, Line}, Acc), Flatten);
        {Port, {data, Data}} ->
            sh_loop(Port, Fun, Fun(Data, Acc), Flatten);
        {Port, {exit_status, Status}} ->
            {done, Status, Flatten(lists:reverse(Acc))}
    end.

%t() -> dbg:tracer(), dbg:p(self(), m), dbg:p(new, m), run("false", "/tmp/1", "/tmp").

ts() ->
    Ts = {{_Y,_M,_D},{_H,_Min,_S}} = calendar:now_to_datetime(now()),
    io_lib:format("~p", [Ts]).
