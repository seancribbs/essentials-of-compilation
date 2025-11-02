import eoc/graph
import eoc/interference_graph as ig
import eoc/langs/l_tup as l
import eoc/langs/x86_base
import eoc/langs/x86_global as x86
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/set

pub fn allocate_registers(input: x86.X86Program) -> x86.X86Program {
  let assignments =
    input.conflicts
    |> color_graph
    |> extract_assignments(input.types)

  let used_callee =
    assignments
    |> dict.values()
    |> list.filter_map(fn(arg) {
      case arg {
        x86.Reg(reg) ->
          case x86_base.is_callee_saved(reg) {
            True -> Ok(reg)
            False -> Error(Nil)
          }

        _ -> Error(Nil)
      }
    })
    |> set.from_list()

  let stack_vars =
    assignments
    |> dict.values()
    |> list.filter_map(fn(arg) {
      case arg {
        x86.Deref(x86_base.Rbp, offset) -> Ok(-offset / 8)
        _ -> Error(Nil)
      }
    })
    |> list.max(int.compare)
    |> result.unwrap(0)

  let root_stack_size =
    assignments
    |> dict.values()
    |> list.filter_map(fn(arg) {
      case arg {
        x86.Deref(x86_base.R15, offset) -> Ok(offset)
        _ -> Error(Nil)
      }
    })
    |> set.from_list()
    |> set.size()

  let body =
    input.body
    |> dict.map_values(fn(_, block) {
      let new_instrs = list.map(block.body, translate_instr(_, assignments))
      x86.Block(..block, body: new_instrs)
    })

  x86.X86Program(..input, body:, stack_vars:, used_callee:, root_stack_size:)
}

fn translate_instr(
  instr: x86.Instr,
  assignments: dict.Dict(x86_base.Location, x86.Arg),
) -> x86.Instr {
  case instr {
    x86.Addq(a, b) ->
      x86.Addq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.Callq(label, arity) -> x86.Callq(label, arity)
    x86.Jmp(label) -> x86.Jmp(label)
    x86.Movq(a, b) ->
      x86.Movq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.Negq(a) -> x86.Negq(translate_location(a, assignments))
    x86.Popq(a) -> x86.Popq(translate_location(a, assignments))
    x86.Pushq(a) -> x86.Pushq(translate_location(a, assignments))
    x86.Retq -> x86.Retq
    x86.Subq(a, b) ->
      x86.Subq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.Cmpq(a:, b:) ->
      x86.Cmpq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.JmpIf(cmp:, label:) -> x86.JmpIf(cmp, label)
    x86.Movzbq(a:, b:) -> x86.Movzbq(a, translate_location(b, assignments))
    x86.Set(cmp:, arg:) -> x86.Set(cmp, arg)
    x86.Xorq(a:, b:) ->
      x86.Xorq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.Andq(a:, b:) ->
      x86.Andq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
    x86.Sarq(a:, b:) ->
      x86.Andq(
        translate_location(a, assignments),
        translate_location(b, assignments),
      )
  }
}

fn translate_location(
  l: x86.Arg,
  assignments: dict.Dict(x86_base.Location, x86.Arg),
) -> x86.Arg {
  case l {
    x86.Var(v) -> {
      let assert Ok(arg) = dict.get(assignments, x86_base.LocVar(v))
      arg
    }
    _ -> l
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

fn pick_vertex(g: ig.Graph) -> Result(x86_base.Location, Nil) {
  g.graph
  |> graph.nodes()
  |> list.filter_map(fn(node) {
    case node.value.assignment {
      Some(_) -> Error(Nil)
      None -> Ok(#(set.size(node.value.saturation), node.id))
    }
  })
  |> list.sort(fn(a, b) {
    case int.compare(a.0, b.0) {
      order.Eq -> x86_base.compare_location(a.1, b.1)
      other -> other
    }
  })
  |> list.max(fn(a, b) { int.compare(a.0, b.0) })
  |> result.map(pair.second)
}

fn extract_assignments(
  g: List(ig.Node),
  types: dict.Dict(String, l.Type),
) -> dict.Dict(x86_base.Location, x86.Arg) {
  list.fold(g, dict.new(), fn(acc, node) {
    let assigner = case node.location {
      x86_base.LocVar(v) ->
        case dict.get(types, v) {
          Ok(l.VectorT(_)) -> rootstack_assignment
          _ -> assignment_to_arg
        }
      _ -> assignment_to_arg
    }
    let assert Some(assignment) = node.assignment
    let arg = assigner(assignment)
    dict.insert(acc, node.location, arg)
  })
}

fn rootstack_assignment(a: Int) -> x86.Arg {
  x86.Deref(x86_base.R15, { -8 * a })
}

fn assignment_to_arg(a: Int) -> x86.Arg {
  case a {
    -1 -> x86.Reg(x86_base.Rax)
    -2 -> x86.Reg(x86_base.Rsp)
    -3 -> x86.Reg(x86_base.Rbp)
    -4 -> x86.Reg(x86_base.R11)
    -5 -> x86.Reg(x86_base.R15)
    0 -> x86.Reg(x86_base.Rcx)
    1 -> x86.Reg(x86_base.Rdx)
    2 -> x86.Reg(x86_base.Rsi)
    3 -> x86.Reg(x86_base.Rdi)
    4 -> x86.Reg(x86_base.R8)
    5 -> x86.Reg(x86_base.R9)
    6 -> x86.Reg(x86_base.R10)
    7 -> x86.Reg(x86_base.Rbx)
    8 -> x86.Reg(x86_base.R12)
    9 -> x86.Reg(x86_base.R13)
    10 -> x86.Reg(x86_base.R14)
    stack -> x86.Deref(x86_base.Rbp, -{ stack - 11 } * 8)
  }
}
