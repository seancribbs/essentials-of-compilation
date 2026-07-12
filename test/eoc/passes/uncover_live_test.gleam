import birdie
import eoc/langs/l_fun as l
import eoc/langs/x86_base.{E, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_def_callq.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Movzbq, Negq, Reg, Set, Var,
  X86Program,
} as x86
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse.{parse, tokens}
import eoc/passes/remove_complex_operands
import eoc/passes/reveal_functions
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
import gleam/dict
import gleam/list
import gleam/set
import pprint

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
    Jmp("main_conclusion"),
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
  let base_block = x86.new_block()
  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([#("start", Block(..base_block, body: instrs))]),
    )

  let p = X86Program([main])
  let p2 =
    X86Program([
      x86.Definition(
        ..main,
        blocks: dict.from_list([
          #("start", Block(body: instrs, live_after:, live_before:)),
        ]),
      ),
    ])

  assert uncover_live.uncover_live(p) == p2
}

pub fn uncover_live_with_callq_test() {
  let instrs = [
    Callq("read_int", 0),
    Addq(Imm(42), Reg(Rax)),
    Jmp("main_conclusion"),
  ]

  let live_before = set.from_list([LocReg(Rsp)])
  let live_after = [
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
    set.from_list([LocReg(Rax), LocReg(Rsp)]),
  ]

  let base_block = x86.new_block()
  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([#("start", Block(..base_block, body: instrs))]),
    )

  let p = X86Program([main])

  let p2 =
    X86Program([
      x86.Definition(
        ..main,
        blocks: dict.from_list([
          #("start", Block(body: instrs, live_after:, live_before:)),
        ]),
      ),
    ])

  assert uncover_live.uncover_live(p) == p2
}

pub fn uncover_live_with_branching_test() {
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
    Jmp("main_conclusion"),
    // [Rax, Rsp]
  ]

  let block_2 = [
    Movq(Var("a"), Reg(Rax)),
    // [a, Rsp]
    Jmp("main_conclusion"),
    // [Rax, Rsp]
  ]

  let main =
    x86.Definition(..x86.new_definition(), label: "main", return: l.IntegerT)

  let p =
    X86Program([
      x86.Definition(
        ..main,
        blocks: dict.from_list([
          #("start", Block(..base_block, body: start)),
          #("block_1", Block(..base_block, body: block_1)),
          #("block_2", Block(..base_block, body: block_2)),
        ]),
      ),
    ])

  let assert x86.X86Program([main2]) = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(main2.blocks, "start")
  assert s.live_before == set.from_list([LocReg(Rsp)])

  let assert Ok(b1) = dict.get(main2.blocks, "block_1")
  assert b1.live_before == set.from_list([LocReg(Rsp)])

  let assert Ok(b2) = dict.get(main2.blocks, "block_2")
  assert b2.live_before == set.from_list([LocReg(Rsp), LocVar("a")])
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
    Jmp("main_conclusion"),
    // [Rax, Rsp]
  ]

  let block_2 = [
    Movq(Imm(2), Reg(Rax)),
    // [Rsp]
    Jmp("main_conclusion"),
    // [Rax, Rsp]
  ]

  let base_block = x86.new_block()
  let main =
    x86.Definition(..x86.new_definition(), label: "main", return: l.IntegerT)

  let p =
    X86Program([
      x86.Definition(
        ..main,
        blocks: dict.from_list([
          #("start", Block(..base_block, body: start)),
          #("block_1", Block(..base_block, body: block_1)),
          #("block_2", Block(..base_block, body: block_2)),
        ]),
      ),
    ])

  let assert x86.X86Program([main2]) = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(main2.blocks, "start")
  assert s.live_before == set.from_list([LocReg(Rsp)])

  let assert Ok(b1) = dict.get(main2.blocks, "block_1")
  assert b1.live_before == set.from_list([LocReg(Rsp)])

  let assert Ok(b2) = dict.get(main2.blocks, "block_2")
  assert b2.live_before == set.from_list([LocReg(Rsp)])

  let assert [_, set_instr, movzbq, ..] = s.live_after
  assert set.contains(set_instr, LocReg(Rax))
  assert !set.contains(movzbq, LocReg(Rax))
  assert set.contains(movzbq, LocVar("x"))
}

pub fn uncover_live_while_loop_test() {
  let p =
    "
  (let ([sum 0])
    (let ([i 5])
      (begin
        (while (> i 0)
          (begin
            (set! sum (+ sum i))
            (set! i (- i 1))))
        sum)))
  "
    |> parsed
    |> prepasses

  let assert x86.X86Program([main]) = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(main.blocks, "main_block_1")
  assert s.live_before == set.from_list([LocVar("sum.1"), LocReg(Rsp)])

  let assert Ok(s) = dict.get(main.blocks, "main")
  assert s.live_before == set.from_list([LocReg(Rsp)])

  let assert Ok(s) = dict.get(main.blocks, "main_block_2")
  assert s.live_before
    == set.from_list([LocVar("sum.1"), LocVar("i.2"), LocReg(Rsp)])

  let assert Ok(s) = dict.get(main.blocks, "main_loop_1")
  assert s.live_before
    == set.from_list([LocVar("sum.1"), LocVar("i.2"), LocReg(Rsp)])
}


pub fn uncover_live_functions_test() {
  let p =
    "
  (define (inc [x : Integer]) : Integer
    (+ x 1))

  (inc 41)
  "
    |> parsed
    |> prepasses

  uncover_live.uncover_live(p).defs
  |> list.map(fn(d) { #(d.label, d.blocks) })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "uncover_live_functions_test blocks")
}

fn parsed(input: String) -> l.Program {
  let assert Ok(toks) = tokens(input)
  let assert Ok(ast) = parse(toks)
  let assert Ok(typed) = l.type_check_program(ast)
  typed
}

fn prepasses(program: l.Program) -> x86.X86Program {
  program
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
  |> limit_functions.limit_functions
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control.explicate_control
  |> select_instructions.select_instructions
}
