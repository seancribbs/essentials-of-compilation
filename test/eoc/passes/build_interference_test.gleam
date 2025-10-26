import eoc/interference_graph as ig
import eoc/langs/l_tup as l
import eoc/langs/x86_base.{E, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_global.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Movzbq, Negq, Reg, Set, Var,
  X86Program,
} as x86
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
import glam/doc
import gleam/dict
import gleam/io
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
  let base_block = x86.new_block()

  let p =
    X86Program(
      ..x86.new_program(),
      body: dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  let p2 = build_interference.build_interference(p)
  let conflicts = p2.conflicts

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

  let base_block = x86.new_block()

  let p =
    X86Program(
      ..x86.new_program(),
      body: dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
    )

  let p2 = build_interference.build_interference(p)
  let conflicts = p2.conflicts

  // callq read_int
  // addq $42, rax
  // jmp conclusion
  ig.has_conflict(conflicts, LocReg(Rax), LocReg(Rsp)) |> should.be_true
}

pub fn build_interference_with_branching_test() {
  let base_block = x86.new_block()

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

  let p =
    X86Program(
      ..x86.new_program(),
      body: dict.from_list([
        #("start", Block(..base_block, body: start)),
        #("block_1", Block(..base_block, body: block_1)),
        #("block_2", Block(..base_block, body: block_2)),
      ]),
    )

  let p2 =
    p |> uncover_live.uncover_live() |> build_interference.build_interference

  let conflicts = p2.conflicts

  // a and %rsp are live at the same time
  ig.has_conflict(conflicts, LocReg(Rsp), LocVar("a")) |> should.be_true
}

pub fn build_interference_assign_boolean_var_test() {
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

  let base_block = x86.new_block()
  let base_program = x86.new_program()

  let p =
    X86Program(
      ..base_program,
      body: dict.from_list([
        #("start", Block(..base_block, body: start)),
        #("block_1", Block(..base_block, body: block_1)),
        #("block_2", Block(..base_block, body: block_2)),
      ]),
    )

  let p2 =
    p |> uncover_live.uncover_live() |> build_interference.build_interference

  let conflicts = p2.conflicts

  ig.has_conflict(conflicts, LocReg(Rsp), LocVar("x")) |> should.be_true
}

pub fn build_interference_vector_test() {
  let p =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses
    |> build_interference.build_interference

  io.println(x86.format_program(p) |> doc.to_string(80))
  // Tuple-typed variables must conflict with callee- and caller-saved registers
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(Rsp)) |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rbp))
  |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rbx))
  |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R12))
  |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R13))
  |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R14))
  |> should.be_true
  ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R15))
  |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rax))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rcx))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rdx))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rsi))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.Rdi))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R8))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R9))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R10))
  // |> should.be_true
  // ig.has_conflict(p.conflicts, LocVar("alloc6"), LocReg(x86_base.R11))
  // |> should.be_true
}

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens
  |> should.be_ok
  |> parse.parse
  |> should.be_ok
}

fn prepasses(input: l.Program) -> x86.X86Program {
  input
  |> l.type_check_program
  |> should.be_ok
  |> shrink.shrink
  |> uniquify.uniquify
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control.explicate_control
  |> select_instructions.select_instructions
  |> uncover_live.uncover_live
}
