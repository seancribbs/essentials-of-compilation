import eoc/langs/x86_base.{LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_var.{
  Addq, Block, Callq, Imm, Jmp, Movq, Negq, Reg, Var, X86Program,
}
import eoc/passes/uncover_live
import gleam/dict
import gleam/set
import gleeunit/should

pub fn uncover_live_figure_35_test() {
  let instrs = [
    Movq(Imm(1), Var("v")),
    Movq(Imm(42), Var("w")),
    Movq(Var("v"), Var("x")),
    Addq(Imm(7), Var("x")),
    Movq(Var("x"), Var("y")),
    Movq(Var("x"), Var("z")),
    Addq(Var("w"), Var("z")),
    Movq(Var("y"), Var("t")),
    Negq(Var("t")),
    Movq(Var("z"), Reg(Rax)),
    Addq(Var("t"), Reg(Rax)),
    Jmp("conclusion"),
  ]
  let live_after = [
    set.from_list([LocVar("v"), LocReg(Rsp)]),
    set.from_list([LocVar("v"), LocVar("w"), LocReg(Rsp)]),
    set.from_list([LocVar("w"), LocVar("x"), LocReg(Rsp)]),
    set.from_list([LocVar("w"), LocVar("x"), LocReg(Rsp)]),
    set.from_list([LocVar("w"), LocVar("x"), LocVar("y"), LocReg(Rsp)]),
    set.from_list([LocVar("w"), LocVar("y"), LocVar("z"), LocReg(Rsp)]),
    set.from_list([LocVar("y"), LocVar("z"), LocReg(Rsp)]),
    set.from_list([LocVar("t"), LocVar("z"), LocReg(Rsp)]),
    set.from_list([LocVar("t"), LocVar("z"), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocVar("t"), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
  ]
  let base_block = x86_var.new_block()

  let p =
    X86Program(dict.from_list([#("start", Block(..base_block, body: instrs))]))
  let p2 =
    X86Program(
      dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  p |> uncover_live.uncover_live |> should.equal(p2)
}

pub fn uncover_live_with_callq_test() {
  let instrs = [
    Callq("read_int", 0),
    Addq(Imm(42), Reg(Rax)),
    Jmp("conclusion"),
  ]

  let live_after = [
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
  ]

  let base_block = x86_var.new_block()

  let p =
    X86Program(dict.from_list([#("start", Block(..base_block, body: instrs))]))
  let p2 =
    X86Program(
      dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  p |> uncover_live.uncover_live |> should.equal(p2)
}
