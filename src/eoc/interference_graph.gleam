import eoc/langs/x86_base as x86
import gleam/dict
import gleam/list
import gleam/set
import graph

pub type Node {
  Node(location: x86.Location)
}

pub type Graph {
  Graph(
    graph: graph.Graph(graph.Undirected, Node, Nil),
    lut: dict.Dict(x86.Location, Int),
    max_id: Int,
  )
}

pub fn new() -> Graph {
  Graph(graph.new(), dict.new(), 0)
  |> add_registers()
}

pub fn add_locations(g: Graph, locations: set.Set(x86.Location)) -> Graph {
  set.fold(locations, g, insert_location)
}

pub fn insert_location(g: Graph, location: x86.Location) -> Graph {
  case dict.has_key(g.lut, location) {
    True -> g
    False -> {
      let next_id = g.max_id + 1
      let lut = dict.insert(g.lut, location, next_id)
      let node = graph.Node(id: next_id, value: Node(location))
      let g = graph.insert_node(g.graph, node)
      Graph(graph: g, lut:, max_id: next_id)
    }
  }
}

pub fn add_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Graph {
  case a == b {
    True -> g
    False -> {
      let assert Ok(aid) = dict.get(g.lut, a)
      let assert Ok(bid) = dict.get(g.lut, b)
      Graph(..g, graph: graph.insert_undirected_edge(g.graph, Nil, aid, bid))
    }
  }
}

pub fn has_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Bool {
  let assert Ok(aid) = dict.get(g.lut, a)
  let assert Ok(bid) = dict.get(g.lut, b)
  graph.has_edge(g.graph, aid, bid)
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
