import eoc/langs/x86_base.{G, L, LocReg, LocVar, Rax, Rcx, Rdx, Rsi, Rsp}
import eoc/langs/x86_if as int
import eoc/langs/x86_var_if.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Negq, Reg, Var, X86Program,
}
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/uncover_live
import gleam/dict
import gleam/set
import gleeunit/should

pub fn allocate_registers_test() {
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
  let base_block = x86_var_if.new_block()

  let p =
    X86Program(
      ..x86_var_if.new_program(),
      body: dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )
    |> build_interference.build_interference()

  let p2 =
    int.X86Program(
      body: dict.from_list([
        #(
          "start",
          int.Block([
            int.Movq(int.Imm(1), int.Reg(Rdx)),
            int.Movq(int.Imm(42), int.Reg(Rcx)),
            int.Movq(int.Reg(Rdx), int.Reg(Rdx)),
            int.Addq(int.Imm(7), int.Reg(Rdx)),
            int.Movq(int.Reg(Rdx), int.Reg(Rsi)),
            int.Movq(int.Reg(Rdx), int.Reg(Rdx)),
            int.Addq(int.Reg(Rcx), int.Reg(Rdx)),
            int.Movq(int.Reg(Rsi), int.Reg(Rcx)),
            int.Negq(int.Reg(Rcx)),
            int.Movq(int.Reg(Rdx), int.Reg(Rax)),
            int.Addq(int.Reg(Rcx), int.Reg(Rax)),
            int.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 0,
      used_callee: set.from_list([]),
    )

  p |> allocate_registers.allocate_registers() |> should.equal(p2)
}

pub fn allocate_registers_branching_test() {
  // a := read()
  // if a > 10 then
  //   b := read()
  //   if b < a then
  //      1
  //   else
  //      2
  //   end
  // else
  //   c := read()
  //   d := read()
  //   c + d
  // end
  let start = [
    Callq("read_int", 0),
    Movq(Reg(Rax), Var("a")),
    Cmpq(Imm(10), Var("a")),
    JmpIf(G, "a_then"),
    Jmp("a_else"),
  ]
  let a_then = [
    Callq("read_int", 0),
    Movq(Reg(Rax), Var("b")),
    Cmpq(Var("a"), Var("b")),
    JmpIf(L, "b_then"),
    Jmp("b_else"),
  ]
  let a_else = [
    Callq("read_int", 0),
    Movq(Reg(Rax), Var("c")),
    Callq("read_int", 0),
    Movq(Reg(Rax), Var("d")),
    Addq(Var("c"), Var("d")),
    Movq(Var("d"), Reg(Rax)),
    Jmp("conclusion"),
  ]
  let b_then = [Movq(Imm(1), Reg(Rax)), Jmp("conclusion")]
  let b_else = [Movq(Imm(2), Reg(Rax)), Jmp("conclusion")]

  let block = x86_var_if.new_block()

  let p =
    X86Program(
      ..x86_var_if.new_program(),
      body: dict.from_list([
        #("start", Block(..block, body: start)),
        #("a_then", Block(..block, body: a_then)),
        #("a_else", Block(..block, body: a_else)),
        #("b_then", Block(..block, body: b_then)),
        #("b_else", Block(..block, body: b_else)),
      ]),
    )

  let p2 =
    p
    |> uncover_live.uncover_live
    |> build_interference.build_interference
    |> allocate_registers.allocate_registers

  let assert Ok(int.Block(body: start_body)) = dict.get(p2.body, "start")
  let start_expected = [
    int.Callq("read_int", 0),
    int.Movq(int.Reg(Rax), int.Reg(Rcx)),
    int.Cmpq(int.Imm(10), int.Reg(Rcx)),
    int.JmpIf(G, "a_then"),
    int.Jmp("a_else"),
  ]
  start_body |> should.equal(start_expected)

  let assert Ok(int.Block(body: a_then_body)) = dict.get(p2.body, "a_then")
  let a_then_expected = [
    int.Callq("read_int", 0),
    int.Movq(int.Reg(Rax), int.Reg(Rdx)),
    int.Cmpq(int.Reg(Rcx), int.Reg(Rdx)),
    int.JmpIf(L, "b_then"),
    int.Jmp("b_else"),
  ]
  a_then_body |> should.equal(a_then_expected)

  let assert Ok(int.Block(body: a_else_body)) = dict.get(p2.body, "a_else")
  let a_else_expected = [
    int.Callq("read_int", 0),
    int.Movq(int.Reg(Rax), int.Reg(Rcx)),
    int.Callq("read_int", 0),
    int.Movq(int.Reg(Rax), int.Reg(Rdx)),
    int.Addq(int.Reg(Rcx), int.Reg(Rdx)),
    int.Movq(int.Reg(Rdx), int.Reg(Rax)),
    int.Jmp("conclusion"),
  ]
  a_else_body |> should.equal(a_else_expected)
}
