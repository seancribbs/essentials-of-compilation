//               | After      | Before
// movq $5, a    | {a}        |  {}
// movq $30, b   | {a}        |  {a}
// movq a, c     | {c}        |  {a}
// movq $10, b   | {b, c}     |  {c}
// addq b, c     | {}         |  {b, c}

import eoc/cfg
import eoc/langs/x86_base.{
  type Location, LocReg, LocVar, Rax, Rsp, bytereg_to_quad,
}
import eoc/langs/x86_var_if.{type Block, Block}
import gleam/dict
import gleam/list
import gleam/result
import gleam/set

pub fn uncover_live(input: x86_var_if.X86Program) -> x86_var_if.X86Program {
  let new_blocks =
    input.body
    |> build_cfg()
    |> analyze_dataflow(input.body)
    |> dict.map_values(fn(block_name, live_sets) {
      let assert Ok(block) = dict.get(input.body, block_name)
      let assert [live_before, ..live_after] = live_sets
      Block(..block, live_before:, live_after:)
    })

  x86_var_if.X86Program(..input, body: new_blocks)
}

type LiveSet =
  set.Set(Location)

type Mapping =
  dict.Dict(String, List(LiveSet))

type Blocks =
  dict.Dict(String, Block)

type CFG =
  cfg.CFG(String, Nil)

type Worklist =
  List(String)

fn analyze_dataflow(g: CFG, blocks: Blocks) -> Mapping {
  let worklist = dict.keys(blocks)
  let mapping =
    worklist
    |> list.map(fn(k) { #(k, []) })
    |> dict.from_list()
    |> dict.insert("conclusion", [set.from_list([LocReg(Rax), LocReg(Rsp)])])

  analyze_dataflow_loop(g, blocks, mapping, worklist)
  |> dict.delete("conclusion")
}

fn analyze_dataflow_loop(
  g: CFG,
  blocks: Blocks,
  mapping: Mapping,
  worklist: Worklist,
) -> Mapping {
  case worklist {
    [] -> mapping
    [node, ..worklist] -> {
      let input =
        g
        |> cfg.in_neighbors(node)
        |> list.fold(set.new(), fn(state, pred) {
          let assert Ok(live_sets) = dict.get(mapping, pred)
          let before =
            live_sets
            |> list.first()
            |> result.unwrap(set.new())

          set.union(state, before)
        })

      let assert Ok(block) = dict.get(blocks, node)
      let output = transfer(block.body, input)
      let assert Ok(previous) = dict.get(mapping, node)
      case output == previous {
        True -> analyze_dataflow_loop(g, blocks, mapping, worklist)
        False ->
          analyze_dataflow_loop(
            g,
            blocks,
            dict.insert(mapping, node, output),
            list.append(worklist, cfg.out_neighbors(g, node)),
          )
      }
    }
  }
}

fn transfer(
  instrs: List(x86_var_if.Instr),
  live_after: LiveSet,
) -> List(LiveSet) {
  use live_after, instr <- list.fold_right(instrs, [live_after])

  let assert Ok(next) = list.first(live_after)
  [before_set(next, instr), ..live_after]
}

fn build_cfg(blocks: Blocks) -> CFG {
  // construct a graph from the dict of blocks
  use g, block_name, block <- dict.fold(blocks, cfg.new())

  // add vertexes for jmp instructions inside the body of each block
  use g, instr <- list.fold(block.body, cfg.add_vertex(g, block_name))

  case instr {
    x86_var_if.JmpIf(cmp: _, label:) | x86_var_if.Jmp(label:) ->
      g
      |> cfg.add_vertex(label)
      |> cfg.add_edge(label, block_name)
    _ -> g
  }
}

fn before_set(after: LiveSet, instr: x86_var_if.Instr) -> LiveSet {
  after
  |> set.difference(write_location_in_inst(instr))
  |> set.union(read_locations_in_inst(instr))
}

pub fn locations_in_arg(arg: x86_var_if.Arg) -> LiveSet {
  case arg {
    // x86_var_if.Deref(_, _) -> todo
    x86_var_if.Imm(_) -> set.new()
    x86_var_if.Reg(reg) -> set.from_list([LocReg(reg)])
    x86_var_if.Var(name) -> set.from_list([LocVar(name)])
  }
}

fn read_locations_in_inst(inst: x86_var_if.Instr) -> LiveSet {
  case inst {
    x86_var_if.Addq(a, b) -> set.union(locations_in_arg(a), locations_in_arg(b))
    x86_var_if.Subq(a, b) -> set.union(locations_in_arg(a), locations_in_arg(b))
    x86_var_if.Movq(a, _) -> locations_in_arg(a)
    x86_var_if.Negq(a) -> locations_in_arg(a)
    x86_var_if.Popq(_) -> set.from_list([LocReg(Rsp)])
    x86_var_if.Pushq(a) ->
      set.union(locations_in_arg(a), set.from_list([LocReg(Rsp)]))
    x86_var_if.Callq(_, arity) ->
      [
        LocReg(x86_base.Rdi),
        LocReg(x86_base.Rsi),
        LocReg(x86_base.Rdx),
        LocReg(x86_base.Rcx),
        LocReg(x86_base.R8),
        LocReg(x86_base.R9),
      ]
      |> list.take(arity)
      |> set.from_list()
    x86_var_if.Retq -> set.from_list([LocReg(Rax)])
    // Correct?
    x86_var_if.Jmp(_) -> set.new()
    // Correct?
    x86_var_if.Cmpq(a:, b:) ->
      set.union(locations_in_arg(a), locations_in_arg(b))
    x86_var_if.JmpIf(cmp: _, label: _) -> set.new()
    x86_var_if.Movzbq(a:, b: _) -> set.from_list([LocReg(bytereg_to_quad(a))])
    x86_var_if.Set(cmp: _, arg: _) -> set.new()
    x86_var_if.Xorq(a:, b:) ->
      set.union(locations_in_arg(a), locations_in_arg(b))
  }
}

pub fn write_location_in_inst(inst: x86_var_if.Instr) -> LiveSet {
  case inst {
    x86_var_if.Addq(_, b) -> locations_in_arg(b)
    x86_var_if.Subq(_, b) -> locations_in_arg(b)
    x86_var_if.Callq(_, _) -> set.from_list([LocReg(Rax)])
    x86_var_if.Movq(_, b) -> locations_in_arg(b)
    x86_var_if.Negq(a) -> locations_in_arg(a)
    x86_var_if.Popq(a) ->
      set.union(locations_in_arg(a), set.from_list([LocReg(Rsp)]))
    x86_var_if.Pushq(_) -> set.from_list([LocReg(Rsp)])
    x86_var_if.Retq -> set.new()
    x86_var_if.Jmp(_) -> set.new()
    x86_var_if.Cmpq(a: _, b: _) -> set.new()
    x86_var_if.JmpIf(cmp: _, label: _) -> set.new()
    x86_var_if.Movzbq(a: _, b:) -> locations_in_arg(b)
    x86_var_if.Set(cmp: _, arg:) ->
      set.from_list([LocReg(bytereg_to_quad(arg))])
    x86_var_if.Xorq(a: _, b:) -> locations_in_arg(b)
  }
}
