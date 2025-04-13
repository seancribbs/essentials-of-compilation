////
//// Here's a handy index you can use to browse through the various graph
//// functions.
////
//// | operation kind | functions |
//// |---|---|
//// | creating graphs | [`new`](#new) |
//// | turning graphs into lists | [`nodes`](#nodes) |
//// | querying a graph | [`size`](#size), [`has_node`](#has_node), [`has_edge`](#has_edge), [`get_context`](#get_context), [`match`](#match) |
//// | adding/removing elements from a graph | [`insert_node`](#insert_node), [`insert_directed_edge`](#insert_directed_edge), [`insert_undirected_edge`](#insert_undirected_edge), [`remove_node`](#remove_node), [`remove_directed_edge`](#remove_directed_edge), [`remove_undirected_edge`](#remove_undirected_edge) |
//// | transforming graphs | [`fold`](#fold), [`reverse`](#reverse), [`map_contexts`](#map_contexts), [`map_values`](#map_values), [`map_labels`](#map_labels), [`reverse_edges`](#reverse_edges), [`to_directed`](#to_directed) |
////

import gleam/dict.{type Dict}
import gleam/result

// --- THE GRAPH TYPE ----------------------------------------------------------

/// An undirected graph. A graph is made up of nodes and edges
/// connecting them: each node holds a `value` and each edge has a `label`.
///
///
pub opaque type Graph(key, value, label) {
  Graph(Dict(key, Context(key, value, label)))
}

/// A node making up a graph. Every node is identified by a number and can hold
/// an arbitrary value.
///
pub type Node(key, value) {
  Node(id: key, value: value)
}

/// The context associated with a node in a graph: it contains the node itself
/// and all the edges. Edges are stored in a dict going
/// from neighbour's id to the edge label.
///
pub type Context(key, value, label) {
  Context(edges: Dict(key, label), node: Node(key, value))
}

// --- CREATING GRAPHS ---------------------------------------------------------

/// Creates a new empty graph.
///
/// ## Examples
///
/// ```gleam
/// nodes(new())
/// // -> []
/// ```
///
pub fn new() -> Graph(key, value, label) {
  Graph(dict.new())
}

// --- TURNING GRAPHS INTO LISTS -----------------------------------------------

/// Returns a list of all the nodes contained in the graph.
///
/// ## Examples
///
/// ```gleam
/// new() |> nodes
/// // -> []
/// ```
///
/// ```gleam
/// new() |> insert_node(Node(1, "a node")) |> nodes
/// // -> [Node(1, "a node")]
/// ```
///
pub fn nodes(graph: Graph(key, value, label)) -> List(Node(key, value)) {
  let Graph(graph) = graph
  use acc, _node_id, Context(node: node, ..) <- dict.fold(over: graph, from: [])
  [node, ..acc]
}

// --- QUERYING A GRAPH --------------------------------------------------------

/// Returns the number of nodes of the graph.
///
/// ## Examples
///
/// ```gleam
/// new() |> size
/// // -> 0
/// ```
///
/// ```gleam
/// new() |> insert_node(Node(1, "a node")) |> size
/// // -> 1
/// ```
///
pub fn size(graph: Graph(key, value, label)) -> Int {
  let Graph(graph) = graph
  dict.size(graph)
}

/// Returns `True` if the graph contains a node with the given id.
///
/// ## Examples
///
/// ```gleam
/// let my_graph = new() |> insert_node(Node(1, "a node"))
///
/// my_graph |> has_node(1)
/// // -> True
///
/// my_graph |> has_node(2)
/// // -> False
/// ```
///
pub fn has_node(graph: Graph(key, value, label), node_id: key) -> Bool {
  let Graph(graph) = graph
  dict.has_key(graph, node_id)
}

/// Returns `True` if the graph has an edge connecting the two nodes with the
/// given ids.
///
/// ## Examples
///
/// ```gleam
/// let my_graph =
///   new()
///   |> insert_node(Node(1, "a node"))
///   |> insert_node(Node(2, "other node"))
///   |> insert_directed_edge("edge label", from: 1, to: 2)
///
/// my_graph |> has_edge(from: 1, to: 2)
/// // -> True
///
/// my_graph |> has_edge(from: 2, to: 1)
/// // -> False
/// ```
///
pub fn has_edge(
  graph: Graph(key, value, label),
  from source: key,
  to destination: key,
) -> Bool {
  case get_context(graph, source) {
    Ok(Context(edges: edges, ..)) -> dict.has_key(edges, destination)
    Error(_) -> False
  }
}

/// Returns the context associated with the node with the given id, if present.
/// Otherwise returns `Error(Nil)`.
///
/// ## Examples
///
/// ```gleam
/// new() |> get(1)
/// // -> Error(Nil)
/// ```
///
/// ```gleam
/// new() |> insert_node(Node(1, "a node")) |> get_context(of: 1)
/// // -> Ok(Context(node: Node(1, "a node"), ..))
/// ```
///
pub fn get_context(
  graph: Graph(key, value, label),
  of node: key,
) -> Result(Context(key, value, label), Nil) {
  let Graph(graph) = graph
  dict.get(graph, node)
}

/// If the graph contains a node with the given id, returns a tuple containing
/// the context of that node (with all edges looping back to itself removed) and
/// the "remaining" graph: that is, the original graph where that node has been
/// removed.
///
pub fn match(
  graph: Graph(key, value, label),
  node_id: key,
) -> Result(#(Context(key, value, label), Graph(key, value, label)), Nil) {
  use Context(edges, node) <- result.try(get_context(graph, node_id))
  let rest = remove_node(graph, node_id)
  let new_edges = dict.delete(edges, node_id)
  Ok(#(Context(new_edges, node), rest))
}

// --- ADDING/REMOVING ELEMENTS FROM A GRAPH -----------------------------------

/// Adds a node to the given graph.
/// If the graph already contains a node with the same id, that will be replaced
/// by the new one.
/// The newly added node won't be connected to any existing node.
///
/// ## Examples
///
/// ```gleam
/// new() |> insert_node(Node(1, "a node")) |> nodes
/// // -> [Node(1, "a node")]
/// ```
///
pub fn insert_node(
  graph: Graph(key, value, label),
  node: Node(key, value),
) -> Graph(key, value, label) {
  let Graph(graph) = graph
  let empty_context = Context(dict.new(), node)
  let new_graph = dict.insert(graph, node.id, empty_context)
  Graph(new_graph)
}

/// Adds an edge connecting two nodes in an undirected graph.
///
/// ## Examples
///
/// ```gleam
/// let my_graph =
///   new()
///   |> insert_node(Node(1, "a node"))
///   |> insert_node(Node(2, "other node"))
///   |> insert_undirected_edge("edge label", between: 1, and: 2)
///
/// my_graph |> has_edge(from: 1, to: 2)
/// // -> True
///
/// my_graph |> has_edge(from: 2, to: 1)
/// // -> True
/// ```
pub fn insert_edge(
  graph: Graph(key, value, label),
  labelled label: label,
  between one: key,
  and other: key,
) -> Graph(key, value, label) {
  graph
  |> update_context(of: one, with: fn(context) {
    add_edge(context, other, label)
  })
  |> update_context(of: other, with: fn(context) {
    add_edge(context, one, label)
  })
}

fn update_context(
  in graph: Graph(key, value, label),
  of node: key,
  with fun: fn(Context(key, value, label)) -> Context(key, value, label),
) -> Graph(key, value, label) {
  let Graph(graph) = graph
  case dict.get(graph, node) {
    Ok(context) -> Graph(dict.insert(graph, node, fun(context)))
    Error(_) -> Graph(graph)
  }
}

fn add_edge(
  context: Context(key, value, label),
  from node: key,
  labelled label: label,
) -> Context(key, value, label) {
  let Context(edges: edges, ..) = context
  Context(..context, edges: dict.insert(edges, node, label))
}

fn remove_edge_internal(
  context: Context(key, value, label),
  from node: key,
) -> Context(key, value, label) {
  let Context(edges: edges, ..) = context
  Context(..context, edges: dict.delete(edges, node))
}

/// Removes a node with the given id from the graph. If there's no node with the
/// given id it does nothing.
///
pub fn remove_node(
  graph: Graph(key, value, label),
  node_id: key,
) -> Graph(key, value, label) {
  case graph, get_context(graph, node_id) {
    _, Error(_) -> graph
    Graph(graph), Ok(Context(edges, _)) ->
      dict.delete(graph, node_id)
      |> remove_occurrences(of: node_id, from: edges)
      |> Graph
  }
}

fn remove_occurrences(
  in graph: Dict(key, Context(key, value, label)),
  of node: key,
  from nodes: Dict(key, a),
) -> Dict(key, Context(key, value, label)) {
  use context, _ <- dict_map_shared_keys(graph, with: nodes)
  let Context(edges: edges, ..) = context
  Context(..context, edges: dict.delete(edges, node))
}

/// Removes an undirected edge connecting two nodes from a graph.
///
pub fn remove_edge(
  graph: Graph(key, value, label),
  between one: key,
  and other: key,
) -> Graph(key, value, label) {
  graph
  |> update_context(of: one, with: fn(context) {
    remove_edge_internal(context, from: other)
  })
  |> update_context(of: other, with: fn(context) {
    remove_edge_internal(context, from: one)
  })
}

// --- TRANSFORMING GRAPHS -----------------------------------------------------

/// Reduces the given graph into a single value by applying function to all its
/// contexts, one after the other.
///
/// > 🚨 Graph's contexts are not sorted in any way so your folding function
/// > should never rely on any accidental order the contexts might have.
///
/// ## Examples
///
/// ```gleam
/// // The size function could be implemented using a fold.
/// // The real implementation is more efficient because it doesn't have to
/// // traverse all contexts!
/// pub fn size(graph) {
///   fold(
///     over: graph,
///     from: 0,
///     with: fn(size, _context) { size + 1 },
///   )
/// }
/// ```
///
pub fn fold(
  over graph: Graph(key, value, label),
  from initial: b,
  with fun: fn(b, Context(key, value, label)) -> b,
) -> b {
  let Graph(graph) = graph
  use acc, _node_id, context <- dict.fold(over: graph, from: initial)
  fun(acc, context)
}

/// Transform the contexts associated with each node.
///
/// > This function can add and remove arbitrary edges from the graph by
/// > updating the `edges` and `outgoing` edges of a context.
/// > So we can't assume the final graph will still be `Undirected`, that's why
/// > it is always treated as a `Directed` one.
///
/// ## Examples
///
/// ```gleam
/// // The reverse function can be implemented with `map_contexts`
/// pub fn reverse(graph) {
///   map_contexts(in: graph, with: fn(context) {
///     Context(
///       ..context,
///       edges: context.outgoing,
///       outgoing: context.edges,
///     )
///   })
/// }
/// ```
///
pub fn map_contexts(
  in graph: Graph(key, value, label),
  with fun: fn(Context(key, value, label)) -> Context(key, value, label),
) -> Graph(key, value, label) {
  use acc, context <- fold(over: graph, from: new())
  insert_context(acc, fun(context))
}

fn insert_context(
  graph: Graph(key, value, label),
  context: Context(key, value, label),
) -> Graph(key, value, label) {
  let Graph(graph) = graph
  let new_graph = dict.insert(graph, context.node.id, context)
  Graph(new_graph)
}

/// Transforms the values of all the graph's nodes using the given function.
///
/// ## Examples
///
/// ```gleam
/// new()
/// |> insert_node(Node(1, "a node"))
/// |> map_nodes(fn(value) { value <> "!" })
/// |> nodes
/// // -> [Node(1, "my node!")]
/// ```
///
pub fn map_values(
  in graph: Graph(key, value, label),
  with fun: fn(value) -> new_value,
) -> Graph(key, new_value, label) {
  let Graph(graph) = graph
  // Since this function doesn't change the graph's topology I'm not
  // implementing it with a `graph.fold` or a `graph.map_contexts`, it would
  // increase code reuse but would rebuild a new graph each time by adding
  // each context one by one.
  Graph({
    use _node_id, context <- dict.map_values(graph)
    let Context(edges, Node(id, value)) = context
    Context(edges, Node(id, fun(value)))
  })
}

/// Transforms the labels of all the graph's edges using the given function.
///
/// ## Examples
///
/// ```
/// new()
/// |> insert_node(Node(1, "a node"))
/// |> insert_undirected_edge(UndirectedEdge(1, 1, "label"))
/// |> map_labels(fn(label) { label <> "!" })
/// |> labels
/// // -> ["label!"]
/// ```
///
pub fn map_labels(
  in graph: Graph(key, value, label),
  with fun: fn(label) -> new_label,
) -> Graph(key, value, new_label) {
  // Since this function doesn't change the graph's topology I'm not
  // implementing it with a `graph.fold` or a `graph.map_contexts`, it would
  // increase code reuse but would rebuild a new graph each time by adding
  // each context one by one.
  let Graph(graph) = graph
  Graph({
    use _node_id, context <- dict.map_values(graph)
    let Context(edges, node) = context
    let new_edges = dict.map_values(edges, fn(_id, label) { fun(label) })
    Context(new_edges, node)
  })
}

// --- DICT UTILITY FUNCTIONS --------------------------------------------------

fn dict_map_shared_keys(
  in one: Dict(k, a),
  with other: Dict(k, b),
  using fun: fn(a, b) -> a,
) -> Dict(k, a) {
  use one, key, other_value <- dict.fold(over: other, from: one)
  case dict.get(one, key) {
    Ok(one_value) -> dict.insert(one, key, fun(one_value, other_value))
    Error(_) -> one
  }
}
