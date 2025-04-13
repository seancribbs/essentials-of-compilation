import eoc/graph
import eoc/langs/x86_base as x86
import gleam/list
import gleam/set

pub type Node {
  Node(location: x86.Location)
}

pub type Graph {
  Graph(graph: graph.Graph(x86.Location, Node, Nil))
}

pub fn new() -> Graph {
  Graph(graph.new())
  |> add_registers()
}

pub fn add_locations(g: Graph, locations: set.Set(x86.Location)) -> Graph {
  set.fold(locations, g, insert_location)
}

pub fn insert_location(g: Graph, location: x86.Location) -> Graph {
  g.graph
  |> graph.insert_node(graph.Node(id: location, value: Node(location)))
  |> Graph
}

pub fn add_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Graph {
  case a == b {
    True -> g
    False -> {
      Graph(graph.insert_edge(g.graph, Nil, a, b))
    }
  }
}

pub fn has_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Bool {
  graph.has_edge(g.graph, a, b)
}

fn add_registers(g: Graph) -> Graph {
  [
    x86.Rsp,
    x86.Rbp,
    x86.Rax,
    x86.Rbx,
    x86.Rcx,
    x86.Rdx,
    x86.Rsi,
    x86.Rdi,
    x86.R8,
    x86.R9,
    x86.R10,
    x86.R11,
    x86.R12,
    x86.R13,
    x86.R14,
    x86.R15,
  ]
  |> list.map(x86.LocReg)
  |> list.fold(g, insert_location)
}
