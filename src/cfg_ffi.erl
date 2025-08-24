-module(cfg_ffi).

-export([
    new/0,
    add_vertex/2,
    add_edge/3,
    in_neighbors/2,
    out_neighbors/2
]).

new() ->
    digraph:new([cyclic]).

add_vertex(G, V) ->
    V = digraph:add_vertex(G, V),
    G.

add_edge(G, V1, V2) ->
    _ = digraph:add_edge(G, V1, V2),
    G.

in_neighbors(G, V) -> digraph:in_neighbours(G, V).

out_neighbors(G, V) -> digraph:out_neighbours(G, V).
