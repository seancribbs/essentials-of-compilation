//               | After      | Before
// movq $5, a    | {a}        |  {}
// movq $30, b   | {a}        |  {a}
// movq a, c     | {c}        |  {a}
// movq $10, b   | {b, c}     |  {c}
// addq b, c     | {}         |  {b, c}

import eoc/cfg
import eoc/langs/x86_base.{type Location, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_var_if.{type Block, Block}
import gleam/dict
import gleam/list
import gleam/set

pub fn uncover_live(input: x86_var_if.X86Program) -> x86_var_if.X86Program {
  let assert Ok(block_order) = build_cfg_order(input.body)

  let new_blocks =
    list.fold(block_order, input.body, fn(blocks, block_name) {
      let assert Ok(block) = dict.get(blocks, block_name)
      let assert [live_before, ..live_after] =
        compute_live_after(block.body, blocks)
      dict.insert(blocks, block_name, Block(..block, live_before:, live_after:))
    })

  x86_var_if.X86Program(..input, body: new_blocks)
}

fn build_cfg_order(
  blocks: dict.Dict(String, Block),
) -> Result(List(String), Nil) {
  blocks
  |> dict.fold(cfg.new(), fn(g, block_name, block) {
    block.body
    |> list.fold(cfg.add_vertex(g, block_name), fn(g, instr) {
      case instr {
        x86_var_if.JmpIf(cmp: _, label:) | x86_var_if.Jmp(label:)
          if label != "conclusion"
        ->
          g
          |> cfg.add_vertex(label)
          |> cfg.add_edge(label, block_name)
        _ -> g
      }
    })
  })
  |> cfg.topsort()
}

fn compute_live_after(
  instrs: List(x86_var_if.Instr),
  blocks: dict.Dict(String, Block),
) -> List(set.Set(Location)) {
  list.fold_right(
    instrs,
    [set.from_list([LocReg(Rax), LocReg(Rsp)])],
    fn(live_after, instr) {
      let assert Ok(after) = list.first(live_after)
      let after = case instr {
        // NOTE: "conclusion" is the end of the program, so it isn't a block that we have generated yet
        x86_var_if.Jmp(label: "conclusion") -> after
        x86_var_if.Jmp(label:) -> {
          let assert Ok(dest) = dict.get(blocks, label)
          dest.live_before
        }
        x86_var_if.JmpIf(cmp: _, label:) -> {
          let assert Ok(dest) = dict.get(blocks, label)
          set.union(dest.live_before, after)
        }
        _ -> after
      }
      [before_set(after, instr), ..live_after]
    },
  )
}

fn before_set(
  after: set.Set(Location),
  instr: x86_var_if.Instr,
) -> set.Set(Location) {
  after
  |> set.difference(write_location_in_inst(instr))
  |> set.union(read_locations_in_inst(instr))
}

pub fn locations_in_arg(arg: x86_var_if.Arg) -> set.Set(Location) {
  case arg {
    // x86_var_if.Deref(_, _) -> todo
    x86_var_if.Imm(_) -> set.new()
    x86_var_if.Reg(reg) -> set.from_list([LocReg(reg)])
    x86_var_if.Var(name) -> set.from_list([LocVar(name)])
  }
}

fn read_locations_in_inst(inst: x86_var_if.Instr) -> set.Set(Location) {
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
    x86_var_if.Movzbq(a: _, b: _) -> set.new()
    x86_var_if.Set(cmp: _, arg: _) -> set.new()
    x86_var_if.Xorq(a:, b:) ->
      set.union(locations_in_arg(a), locations_in_arg(b))
  }
}

pub fn write_location_in_inst(inst: x86_var_if.Instr) -> set.Set(Location) {
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
    x86_var_if.Set(cmp: _, arg: _) -> set.new()
    x86_var_if.Xorq(a: _, b:) -> locations_in_arg(b)
  }
}
