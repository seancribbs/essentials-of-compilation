import eoc/langs/l_if
import eoc/langs/x86_base.{E, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_var_if.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Movzbq, Negq, Reg, Set, Var,
  X86Program,
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
  let live_before = set.from_list([LocReg(Rsp)])
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
  let base_block = x86_var_if.new_block()
  let base_program = x86_var_if.new_program()

  let p =
    X86Program(
      ..base_program,
      body: dict.from_list([#("start", Block(..base_block, body: instrs))]),
    )
  let p2 =
    X86Program(
      ..base_program,
      body: dict.from_list([
        #("start", Block(body: instrs, live_after:, live_before:)),
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

  let live_before = set.from_list([LocReg(Rsp)])
  let live_after = [
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
  ]

  let base_block = x86_var_if.new_block()
  let base_program = x86_var_if.new_program()

  let p =
    X86Program(
      ..base_program,
      body: dict.from_list([#("start", Block(..base_block, body: instrs))]),
    )
  let p2 =
    X86Program(
      ..base_program,
      body: dict.from_list([
        #("start", Block(body: instrs, live_after:, live_before:)),
      ]),
    )

  p |> uncover_live.uncover_live |> should.equal(p2)
}

pub fn uncover_live_with_branching_test() {
  let base_block = x86_var_if.new_block()

  let start = [
    Callq("read_int", 0),
    // [Rsp]
    Movq(Reg(Rax), Var("a")),
    // [Rax, Rsp]
    Addq(Imm(42), Var("a")),
    // [a, Rsp]
    Cmpq(Imm(0), Var("a")),
    // [a, Rsp]
    JmpIf(E, "block_1"),
    // [a, Rsp]
    Jmp("block_2"),
    // [a, Rsp]
  ]

  let block_1 = [
    Movq(Imm(0), Reg(Rax)),
    // [Rsp]
    Jmp("conclusion"),
    // [Rax, Rsp]
  ]

  let block_2 = [
    Movq(Var("a"), Reg(Rax)),
    // [a, Rsp]
    Jmp("conclusion"),
    // [Rax, Rsp]
  ]

  let base_program = x86_var_if.new_program()

  let p =
    X86Program(
      ..base_program,
      body: dict.from_list([
        #("start", Block(..base_block, body: start)),
        #("block_1", Block(..base_block, body: block_1)),
        #("block_2", Block(..base_block, body: block_2)),
      ]),
    )

  let p2 = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(p2.body, "start")
  s.live_before |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert Ok(b1) = dict.get(p2.body, "block_1")
  b1.live_before |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert Ok(b2) = dict.get(p2.body, "block_2")
  b2.live_before |> should.equal(set.from_list([LocReg(Rsp), LocVar("a")]))
}

pub fn uncover_live_assign_boolean_var_test() {
  // x := 5 < 10
  // if x then 1 else 2

  let start = [
    Cmpq(Imm(10), Imm(5)),
    // [Rsp]
    Set(x86_base.L, x86_base.Al),
    // [Rsp]
    Movzbq(x86_base.Al, Var("x")),
    // [Rax, Rsp]
    Cmpq(Imm(1), Var("x")),
    // [x, Rsp]
    JmpIf(E, "block_1"),
    // [Rsp]
    Jmp("block_2"),
    // [Rsp]
  ]

  let block_1 = [
    Movq(Imm(1), Reg(Rax)),
    // [Rsp]
    Jmp("conclusion"),
    // [Rax, Rsp]
  ]

  let block_2 = [
    Movq(Imm(2), Reg(Rax)),
    // [Rsp]
    Jmp("conclusion"),
    // [Rax, Rsp]
  ]

  let base_block = x86_var_if.new_block()
  let base_program = x86_var_if.new_program()

  let p =
    X86Program(
      ..base_program,
      body: dict.from_list([
        #("start", Block(..base_block, body: start)),
        #("block_1", Block(..base_block, body: block_1)),
        #("block_2", Block(..base_block, body: block_2)),
      ]),
    )

  let p2 = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(p2.body, "start")
  s.live_before |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert Ok(b1) = dict.get(p2.body, "block_1")
  b1.live_before |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert Ok(b2) = dict.get(p2.body, "block_2")
  b2.live_before |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert [_, set_instr, movzbq, ..] = s.live_after
  set.contains(set_instr, LocReg(Rax)) |> should.be_true
  set.contains(movzbq, LocReg(Rax)) |> should.be_false
  set.contains(movzbq, LocVar("x")) |> should.be_true
}
