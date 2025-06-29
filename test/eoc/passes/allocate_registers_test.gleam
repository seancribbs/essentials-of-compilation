import eoc/langs/x86_base.{LocReg, LocVar, Rax, Rcx, Rdx, Rsi, Rsp}
import eoc/langs/x86_int as int
import eoc/langs/x86_var_if.{
  Addq, Block, Imm, Jmp, Movq, Negq, Reg, Var, X86Program,
}
import eoc/passes/allocate_registers
import eoc/passes/build_interference
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
      dict.from_list([
        #(
          "start",
          int.Block(
            [
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
            ],
            0,
            set.from_list([]),
          ),
        ),
      ]),
    )
  // p |> allocate_registers.allocate_registers() |> should.equal(p2)
}
