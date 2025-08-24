-module(runtime_ffi).

-export([read_int/0]).

read_int() ->
    case io:get_line("> ") of
        eof -> exit(eof);
        {error, Err} -> exit(Err);
        Data -> binary_to_integer(iolist_to_binary(Data))
    end.
