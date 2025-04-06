//               | After      | Before
// movq $5, a    | {a}        |  {}
// movq $30, b   | {a}        |  {a}
// movq a, c     | {c}        |  {a}
// movq $10, b   | {b, c}     |  {c}
// addq b, c     | {}         |  {b, c}

import eoc/langs/x86_base.{type Location, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_var.{Block}
import gleam/dict
import gleam/list
import gleam/set

pub fn uncover_live(input: x86_var.X86Program) -> x86_var.X86Program {
  input.body
  |> dict.map_values(fn(_, block) {
    Block(..block, live_after: compute_live_after(block.body))
  })
  |> x86_var.X86Program()
}

fn compute_live_after(instrs: List(x86_var.Instr)) -> List(set.Set(Location)) {
  let assert [_, ..tail] = instrs
  list.fold_right(
    tail,
    [set.from_list([LocReg(Rax), LocReg(Rsp)])],
    fn(live_after, instr) {
      let assert Ok(after) = list.first(live_after)
      [before_set(after, instr), ..live_after]
    },
  )
}

fn before_set(
  after: set.Set(Location),
  instr: x86_var.Instr,
) -> set.Set(Location) {
  after
  |> set.difference(write_location_in_inst(instr))
  |> set.union(read_locations_in_inst(instr))
}

pub fn locations_in_arg(arg: x86_var.Arg) -> set.Set(Location) {
  case arg {
    // x86_var.Deref(_, _) -> todo
    x86_var.Imm(_) -> set.new()
    x86_var.Reg(reg) -> set.from_list([LocReg(reg)])
    x86_var.Var(name) -> set.from_list([LocVar(name)])
  }
}

fn read_locations_in_inst(inst: x86_var.Instr) -> set.Set(Location) {
  case inst {
    x86_var.Addq(a, b) -> set.union(locations_in_arg(a), locations_in_arg(b))
    x86_var.Subq(a, b) -> set.union(locations_in_arg(a), locations_in_arg(b))
    x86_var.Movq(a, _) -> locations_in_arg(a)
    x86_var.Negq(a) -> locations_in_arg(a)
    x86_var.Popq(_) -> set.from_list([LocReg(Rsp)])
    x86_var.Pushq(a) ->
      set.union(locations_in_arg(a), set.from_list([LocReg(Rsp)]))
    x86_var.Callq(_, arity) ->
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
    x86_var.Retq -> set.from_list([LocReg(Rax)])
    // Correct?
    x86_var.Jmp(_) -> set.new()
    // Correct?
  }
}

pub fn write_location_in_inst(inst: x86_var.Instr) -> set.Set(Location) {
  case inst {
    x86_var.Addq(_, b) -> locations_in_arg(b)
    x86_var.Subq(_, b) -> locations_in_arg(b)
    x86_var.Callq(_, _) -> set.from_list([LocReg(Rax)])
    x86_var.Movq(_, b) -> locations_in_arg(b)
    x86_var.Negq(a) -> locations_in_arg(a)
    x86_var.Popq(a) ->
      set.union(locations_in_arg(a), set.from_list([LocReg(Rsp)]))
    x86_var.Pushq(_) -> set.from_list([LocReg(Rsp)])
    x86_var.Retq -> set.new()
    // Correct?
    x86_var.Jmp(_) -> set.new()
    // Correct?
  }
}
