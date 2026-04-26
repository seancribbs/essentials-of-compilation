import gleam/dict
import gleam/option
import gleam/result
import gleam/set

// pub type Context(key, weight) {
//   Context(weight: weight, incoming: Set(key), outgoing: Set(key))
// }

pub type Graph(key, weight) {
  Graph(
    nodes: dict.Dict(key, weight),
    incoming: dict.Dict(key, set.Set(key)),
    outgoing: dict.Dict(key, set.Set(key)),
  )
}

pub fn new() -> Graph(key, weight) {
  Graph(nodes: dict.new(), incoming: dict.new(), outgoing: dict.new())
}

pub fn insert_node(
  graph: Graph(key, weight),
  key: key,
  weight: weight,
) -> Graph(key, weight) {
  let nodes = dict.insert(graph.nodes, key, weight)
  Graph(..graph, nodes:)
}

pub fn insert_undirected_edge(
  graph: Graph(key, weight),
  from: key,
  to: key,
) -> Graph(key, weight) {
  graph
  |> insert_directed_edge(from, to)
  |> insert_directed_edge(to, from)
}

pub fn insert_directed_edge(
  graph: Graph(key, weight),
  from: key,
  to: key,
) -> Graph(key, weight) {
  let incoming =
    dict.upsert(graph.incoming, to, fn(inc) {
      inc |> option.lazy_unwrap(set.new) |> set.insert(from)
    })
  let outgoing =
    dict.upsert(graph.outgoing, from, fn(out) {
      out |> option.lazy_unwrap(set.new) |> set.insert(to)
    })
  Graph(..graph, incoming:, outgoing:)
}

pub fn in_neighbors(graph: Graph(key, weight), node: key) -> set.Set(key) {
  graph.incoming
  |> dict.get(node)
  |> result.lazy_unwrap(set.new)
}

pub fn out_neighbors(graph: Graph(key, weight), node: key) -> set.Set(key) {
  graph.outgoing
  |> dict.get(node)
  |> result.lazy_unwrap(set.new)
}

pub fn get_node(graph: Graph(key, weight), node: key) -> Result(weight, Nil) {
  dict.get(graph.nodes, node)
}

pub fn modify(
  graph: Graph(key, weight),
  node: key,
  with: fn(weight) -> weight,
) -> Graph(key, weight) {
  let assert Ok(weight) = dict.get(graph.nodes, node)
  Graph(..graph, nodes: dict.insert(graph.nodes, node, with(weight)))
}

pub fn has_edge(graph: Graph(key, weight), from: key, to: key) -> Bool {
  graph.outgoing
  |> dict.get(from)
  |> result.lazy_unwrap(set.new)
  |> set.contains(to)
}

pub fn node_weights(graph: Graph(key, weight)) -> List(weight) {
  dict.values(graph.nodes)
}
