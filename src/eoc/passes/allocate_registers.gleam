import eoc/graph
import eoc/interference_graph as ig
import eoc/langs/x86_base as x86
import eoc/langs/x86_int as int
import eoc/langs/x86_var as var
import gleam/dict
import gleam/int as gleam_int
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/set

pub fn allocate_registers(input: var.X86Program) -> int.X86Program {
  input.body
  |> dict.map_values(fn(_, block) { allocate_registers_block(block) })
  |> int.X86Program()
}

fn allocate_registers_block(input: var.Block) -> int.Block {
  let var.Block(instrs, _, conflicts) = input
  let assignments =
    conflicts
    |> color_graph()
    |> extract_assignments()
  // Translate all the instructions with looking up their locations
  let new_instrs = list.map(instrs, translate_instr(_, assignments))
  int.Block(new_instrs, 0)
}

fn translate_instr(
  instr: var.Instr,
  assignments: dict.Dict(x86.Location, int.Arg),
) -> int.Instr {
  case instr {
    var.Addq(a, b) ->
      int.Addq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    var.Callq(label, arity) -> int.Callq(label, arity)
    var.Jmp(label) -> int.Jmp(label)
    var.Movq(a, b) ->
      int.Movq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    var.Negq(a) -> int.Negq(translate_location(a, assignments))
    var.Popq(a) -> int.Popq(translate_location(a, assignments))
    var.Pushq(a) -> int.Pushq(translate_location(a, assignments))
    var.Retq -> int.Retq
    var.Subq(a, b) ->
      int.Subq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
  }
}

fn translate_location(
  l: var.Arg,
  assignments: dict.Dict(x86.Location, int.Arg),
) -> int.Arg {
  case l {
    var.Imm(i) -> int.Imm(i)
    var.Reg(r) -> int.Reg(r)
    var.Var(v) -> {
      let assert Ok(arg) = dict.get(assignments, x86.LocVar(v))
      arg
    }
  }
}

fn color_graph(g: ig.Graph) -> List(ig.Node) {
  unfold(g, color_graph_step, [])
}

fn unfold(
  initial: acc,
  generator: fn(acc) -> Result(#(item, acc), Nil),
  result: List(item),
) -> List(item) {
  case generator(initial) {
    Ok(#(item, next_acc)) -> unfold(next_acc, generator, [item, ..result])
    Error(_) -> result
  }
}

fn color_graph_step(g: ig.Graph) -> Result(#(ig.Node, ig.Graph), Nil) {
  // Until all vertices have assignments:
  //   Pick an unassigned vertex with the highest saturation (breaking ties randomly)
  case pick_vertex(g) {
    Ok(location) -> {
      let assert Ok(#(context, graph)) = graph.match(g.graph, location)
      // Find the lowest color c that is not in the colors of adjacent nodes (saturation set)
      let color = pick_color(context.node.value.saturation)
      // Assign the color c to the current vertex
      let value = ig.Node(..context.node.value, assignment: Some(color))
      //     - Update all adjacent nodes to include the assigned color in their saturation set
      let new_graph =
        context.edges
        |> dict.keys()
        |> list.fold(graph, fn(g, node_id) {
          graph.modify_value(g, node_id, fn(node) {
            ig.Node(..node, saturation: set.insert(node.saturation, color))
          })
        })
      Ok(#(value, ig.Graph(new_graph)))
    }
    _ -> Error(Nil)
  }
}

fn pick_color(set: set.Set(Int)) -> Int {
  pick_color_internal(set, 0)
}

fn pick_color_internal(set: set.Set(Int), candidate: Int) -> Int {
  case set.contains(set, candidate) {
    True -> pick_color_internal(set, candidate + 1)
    False -> candidate
  }
}

fn pick_vertex(g: ig.Graph) -> Result(x86.Location, Nil) {
  g.graph
  |> graph.nodes()
  |> list.filter_map(fn(node) {
    case node.value.assignment {
      Some(_) -> Error(Nil)
      None -> Ok(#(set.size(node.value.saturation), node.id))
    }
  })
  |> list.max(fn(a, b) { gleam_int.compare(a.0, b.0) })
  |> result.map(pair.second)
}

fn extract_assignments(g: List(ig.Node)) -> dict.Dict(x86.Location, int.Arg) {
  list.fold(g, dict.new(), fn(acc, node) {
    let assert Some(assignment) = node.assignment
    let arg = assignment_to_arg(assignment)
    dict.insert(acc, node.location, arg)
  })
}

fn assignment_to_arg(a: Int) -> int.Arg {
  case a {
    -1 -> int.Reg(x86.Rax)
    -2 -> int.Reg(x86.Rsp)
    -3 -> int.Reg(x86.Rbp)
    -4 -> int.Reg(x86.R11)
    -5 -> int.Reg(x86.R15)
    0 -> int.Reg(x86.Rcx)
    1 -> int.Reg(x86.Rdx)
    2 -> int.Reg(x86.Rsi)
    3 -> int.Reg(x86.Rdi)
    4 -> int.Reg(x86.R8)
    5 -> int.Reg(x86.R9)
    6 -> int.Reg(x86.R10)
    7 -> int.Reg(x86.Rbx)
    8 -> int.Reg(x86.R12)
    9 -> int.Reg(x86.R13)
    10 -> int.Reg(x86.R14)
    stack -> int.Deref(x86.Rbp, -{ stack - 11 } * 8)
  }
}
