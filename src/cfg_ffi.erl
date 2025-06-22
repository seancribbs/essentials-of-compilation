-module(cfg_ffi).

-export([
    new/0,
    topsort/1,
    add_vertex/2,
    add_edge/3
]).

new() ->
    digraph:new([acyclic]).

topsort(G) ->
    case digraph_utils:topsort(G) of
        L when is_list(L) -> {ok, L};
        false -> {error, nil}
    end.

add_vertex(G, V) ->
    V = digraph:add_vertex(G, V),
    G.

add_edge(G, V1, V2) ->
    _ = digraph:add_edge(G, V1, V2),
    G.
