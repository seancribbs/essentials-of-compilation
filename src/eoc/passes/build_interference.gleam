import eoc/interference_graph
import eoc/langs/l_fun as l
import eoc/langs/x86_base
import eoc/langs/x86_def_callq as x86
import eoc/passes/uncover_live
import gleam/dict
import gleam/list
import gleam/set

pub fn build_interference(program: x86.X86Program) -> x86.X86Program {
  x86.X86Program(defs: list.map(program.defs, build_interference_definition))
}

pub fn build_interference_definition(def: x86.Definition) -> x86.Definition {
  let conflicts =
    dict.fold(def.blocks, def.conflicts, fn(ig, _, block) {
      determine_conflicts(ig, block.body, block.live_after, def.types)
    })
  x86.Definition(..def, conflicts:)
}

fn determine_conflicts(
  ig: interference_graph.Graph,
  body: List(x86.Instr),
  live_after: List(set.Set(x86_base.Location)),
  types: dict.Dict(String, l.Type),
) -> interference_graph.Graph {
  body
  |> list.zip(live_after)
  |> list.fold(ig, fn(g, pair) {
    let #(instr, live) = pair
    case instr {
      x86.Movzbq(s, d) ->
        rule_1(
          g,
          set.from_list([x86_base.LocReg(x86_base.bytereg_to_quad(s))]),
          uncover_live.locations_in_arg(d),
          live,
        )
      x86.Movq(s, d) ->
        rule_1(
          g,
          uncover_live.locations_in_arg(s),
          uncover_live.locations_in_arg(d),
          live,
        )
      x86.IndirectCallq(_, _) as i | x86.Callq(_, _) as i -> {
        let g = rule_2(g, uncover_live.write_location_in_inst(i), live)
        set.fold(live, g, fn(g, loc) {
          case loc {
            x86_base.LocVar(name:) -> {
              case dict.get(types, name) {
                Ok(l.VectorT(_)) -> {
                  list.fold(x86_base.callee_saved_registers, g, fn(g, reg) {
                    interference_graph.add_conflict(
                      g,
                      loc,
                      x86_base.LocReg(reg),
                    )
                  })
                }
                _ -> g
              }
            }
            x86_base.LocReg(reg: _) -> g
          }
        })
      }
      i -> rule_2(g, uncover_live.write_location_in_inst(i), live)
    }
  })
}

fn rule_1(
  g: interference_graph.Graph,
  s: set.Set(x86_base.Location),
  d: set.Set(x86_base.Location),
  live: set.Set(x86_base.Location),
) -> interference_graph.Graph {
  let g =
    s
    |> set.union(d)
    |> set.union(live)
    |> interference_graph.add_locations(g, _)

  set.fold(live, g, fn(g, loc) {
    case !set.contains(s, loc) && !set.contains(d, loc) {
      True ->
        set.fold(d, g, fn(g, d) { interference_graph.add_conflict(g, d, loc) })
      False -> g
    }
  })
}

fn rule_2(
  g: interference_graph.Graph,
  w: set.Set(x86_base.Location),
  live: set.Set(x86_base.Location),
) -> interference_graph.Graph {
  let g = w |> set.union(live) |> interference_graph.add_locations(g, _)
  set.fold(w, g, fn(g, d) {
    set.fold(live, g, fn(g, v) {
      case v != d {
        True -> interference_graph.add_conflict(g, d, v)
        False -> g
      }
    })
  })
}
