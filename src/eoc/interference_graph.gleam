import eoc/graph
import eoc/langs/x86_base as x86
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/set

pub type Node {
  Node(
    location: x86.Location,
    assignment: Option(Int),
    saturation: set.Set(Int),
  )
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
  case graph.has_node(g.graph, location) {
    True -> g
    False ->
      g.graph
      |> graph.insert_node(graph.Node(
        id: location,
        value: Node(location, None, set.new()),
      ))
      |> Graph
  }
}

pub fn add_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Graph {
  case a == b {
    True -> g
    False -> {
      let assert Ok(a_context) = graph.get_context(g.graph, a)
      let assert Ok(b_context) = graph.get_context(g.graph, b)
      g.graph
      |> graph.insert_edge(Nil, a, b)
      |> graph.modify_value(a, fn(node) {
        case b_context.node.value.assignment {
          Some(i) -> {
            Node(..node, saturation: set.insert(node.saturation, i))
          }
          None -> node
        }
      })
      |> graph.modify_value(b, fn(node) {
        case a_context.node.value.assignment {
          Some(i) -> {
            Node(..node, saturation: set.insert(node.saturation, i))
          }
          None -> node
        }
      })
      |> Graph
    }
  }
}

pub fn has_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Bool {
  graph.has_edge(g.graph, a, b)
}

fn add_registers(g: Graph) -> Graph {
  [
    #(x86.Rax, -1),
    #(x86.Rsp, -2),
    #(x86.Rbp, -3),
    #(x86.R11, -4),
    #(x86.R15, -5),
    #(x86.Rcx, 0),
    #(x86.Rdx, 1),
    #(x86.Rsi, 2),
    #(x86.Rdi, 3),
    #(x86.R8, 4),
    #(x86.R9, 5),
    #(x86.R10, 6),
    #(x86.Rbx, 7),
    #(x86.R12, 8),
    #(x86.R13, 9),
    #(x86.R14, 10),
  ]
  |> list.map(fn(pair) {
    let #(reg, color) = pair
    let location = x86.LocReg(reg)
    graph.Node(
      id: location,
      value: Node(location:, assignment: Some(color), saturation: set.new()),
    )
  })
  |> list.fold(g.graph, graph.insert_node)
  |> Graph
}
