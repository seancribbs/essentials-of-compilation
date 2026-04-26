import eoc/graf
import gleam/set

pub fn empty_graph_has_no_nodes_test() {
  let g = graf.new()
  assert Error(Nil) == graf.get_node(g, "foo")
}

pub fn graph_with_one_node_test() {
  let g = graf.new() |> graf.insert_node("foo", "bar")
  assert Ok("bar") == graf.get_node(g, "foo")
  assert set.new() == graf.in_neighbors(g, "foo")
  assert set.new() == graf.out_neighbors(g, "foo")
  assert !graf.has_edge(g, "foo", "baz")
}

pub fn graph_with_undirected_edges_test() {
  let g =
    graf.new()
    |> graf.insert_node("foo", 1)
    |> graf.insert_node("bar", 2)
    |> graf.insert_undirected_edge("foo", "bar")

  assert graf.has_edge(g, "foo", "bar")
  assert graf.has_edge(g, "bar", "foo")

  assert set.from_list(["foo"]) == graf.in_neighbors(g, "bar")
  assert set.from_list(["foo"]) == graf.out_neighbors(g, "bar")
  assert set.from_list(["bar"]) == graf.in_neighbors(g, "foo")
  assert set.from_list(["bar"]) == graf.out_neighbors(g, "foo")
}

pub fn graph_with_directed_edges_test() {
  let g =
    graf.new()
    |> graf.insert_node("foo", 1)
    |> graf.insert_node("bar", 2)
    |> graf.insert_directed_edge("foo", "bar")

  assert graf.has_edge(g, "foo", "bar")
  assert !graf.has_edge(g, "bar", "foo")

  assert set.from_list(["foo"]) == graf.in_neighbors(g, "bar")
  assert set.from_list(["bar"]) == graf.out_neighbors(g, "foo")
  assert set.new() == graf.in_neighbors(g, "foo")
  assert set.new() == graf.out_neighbors(g, "bar")
}

pub fn graph_modification_test() {
  let g =
    graf.new()
    |> graf.insert_node("foo", 1)
    |> graf.modify("foo", fn(i) { i * 100 })

  assert Ok(100) == graf.get_node(g, "foo")
}

pub fn graph_node_weights_test() {
  let g =
    graf.new()
    |> graf.insert_node("foo", 1)
    |> graf.insert_node("bar", 2)

  assert set.from_list([1, 2]) == set.from_list(graf.node_weights(g))
}
