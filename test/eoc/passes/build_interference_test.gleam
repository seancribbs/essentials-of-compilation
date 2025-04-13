import eoc/interference_graph as ig
import eoc/langs/x86_base.{LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_var.{
  Addq, Block, Callq, Imm, Jmp, Movq, Negq, Reg, Var, X86Program,
}
import eoc/passes/build_interference
import gleam/dict
import gleam/set
import gleeunit/should

// import gleam/io
pub fn build_interference_test() {
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
    X86Program(
      dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  let p2 = build_interference.build_interference(p)
  let assert Ok(block) = dict.get(p2.body, "start")
  let conflicts = block.conflicts

  // io.debug(conflicts)
  // movq $1, v v interferes with rsp,
  ig.has_conflict(conflicts, LocVar("v"), LocReg(Rsp)) |> should.be_true
  // movq $42, w w interferes with v and rsp,
  ig.has_conflict(conflicts, LocVar("w"), LocVar("v")) |> should.be_true
  ig.has_conflict(conflicts, LocVar("w"), LocReg(Rsp)) |> should.be_true
  // movq v, x x interferes with w and rsp,
  // addq $7, x x interferes with w and rsp,
  ig.has_conflict(conflicts, LocVar("x"), LocVar("w")) |> should.be_true
  ig.has_conflict(conflicts, LocVar("x"), LocReg(Rsp)) |> should.be_true
  // movq x, y y interferes with w and rsp but not x,
  ig.has_conflict(conflicts, LocVar("y"), LocReg(Rsp)) |> should.be_true
  ig.has_conflict(conflicts, LocVar("y"), LocVar("w")) |> should.be_true
  ig.has_conflict(conflicts, LocVar("y"), LocVar("x")) |> should.be_false
  // movq x, z z interferes with w, y, and rsp,
  // addq w, z z interferes with y and rsp,
  ig.has_conflict(conflicts, LocVar("z"), LocReg(Rsp)) |> should.be_true
  ig.has_conflict(conflicts, LocVar("z"), LocVar("w")) |> should.be_true
  ig.has_conflict(conflicts, LocVar("z"), LocVar("y")) |> should.be_true
  // movq y, t t interferes with z and rsp,
  // negq t t interferes with z and rsp,
  ig.has_conflict(conflicts, LocVar("t"), LocVar("z")) |> should.be_true
  ig.has_conflict(conflicts, LocVar("t"), LocReg(Rsp)) |> should.be_true
  // movq z, %rax rax interferes with t and rsp,
  // addq t, %rax rax interferes with rsp,
  ig.has_conflict(conflicts, LocReg(Rax), LocVar("t")) |> should.be_true
  ig.has_conflict(conflicts, LocReg(Rax), LocReg(Rsp)) |> should.be_true
  // jmp conclusion no interference
}

pub fn build_interference_call_test() {
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
    X86Program(
      dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  let p2 = build_interference.build_interference(p)
  let assert Ok(block) = dict.get(p2.body, "start")
  let conflicts = block.conflicts

  // callq read_int
  // addq $42, rax
  // jmp conclusion
  ig.has_conflict(conflicts, LocReg(Rax), LocReg(Rsp)) |> should.be_true
}
