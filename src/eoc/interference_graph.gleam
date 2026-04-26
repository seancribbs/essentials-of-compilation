import eoc/graf
import eoc/langs/x86_base as x86
import gleam/bool
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

pub type Graph =
  graf.Graph(x86.Location, Node)

pub fn new() -> Graph {
  graf.new()
  |> add_registers()
}

pub fn add_locations(g: Graph, locations: set.Set(x86.Location)) -> Graph {
  set.fold(locations, g, insert_location)
}

pub fn insert_location(g: Graph, location: x86.Location) -> Graph {
  case graf.get_node(g, location) {
    Ok(_) -> g
    Error(Nil) -> graf.insert_node(g, location, Node(location, None, set.new()))
  }
}

pub fn add_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Graph {
  use <- bool.guard(when: a == b, return: g)

  let assert Ok(a_node) = graf.get_node(g, a)
  let assert Ok(b_node) = graf.get_node(g, b)

  g
  |> graf.insert_undirected_edge(a, b)
  |> graf.modify(a, fn(node) {
    case b_node.assignment {
      Some(i) -> Node(..node, saturation: set.insert(node.saturation, i))
      None -> node
    }
  })
  |> graf.modify(b, fn(node) {
    case a_node.assignment {
      Some(i) -> Node(..node, saturation: set.insert(node.saturation, i))
      None -> node
    }
  })
}

pub fn has_conflict(g: Graph, a: x86.Location, b: x86.Location) -> Bool {
  graf.has_edge(g, a, b)
}

const register_colors = [
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

fn add_registers(g: Graph) -> Graph {
  list.fold(register_colors, g, fn(g, pair) {
    let #(reg, color) = pair
    let location = x86.LocReg(reg)
    let node = Node(location:, assignment: Some(color), saturation: set.new())
    graf.insert_node(g, location, node)
  })
}
