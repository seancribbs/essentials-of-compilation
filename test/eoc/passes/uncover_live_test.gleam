import eoc/langs/l_tup as l
import eoc/langs/x86_base.{E, LocReg, LocVar, Rax, Rsp}
import eoc/langs/x86_global.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Movzbq, Negq, Reg, Set, Var,
  X86Program,
} as x86
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/parse.{parse, tokens}
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
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
  let base_block = x86.new_block()
  let base_program = x86.new_program()

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

  let base_block = x86.new_block()
  let base_program = x86.new_program()

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
    |> shrink.shrink
    |> uniquify.uniquify
    |> expose_allocation.expose_allocation
    |> uncover_get.uncover_get
    |> remove_complex_operands.remove_complex_operands
    |> explicate_control.explicate_control
    |> select_instructions.select_instructions

  let p2 = uncover_live.uncover_live(p)

  let assert Ok(s) = dict.get(p2.body, "block_1")
  s.live_before |> should.equal(set.from_list([LocVar("sum.1"), LocReg(Rsp)]))

  let assert Ok(s) = dict.get(p2.body, "start")
  s.live_before
  |> should.equal(set.from_list([LocReg(Rsp)]))

  let assert Ok(s) = dict.get(p2.body, "block_2")
  s.live_before
  |> should.equal(set.from_list([LocVar("sum.1"), LocVar("i.2"), LocReg(Rsp)]))

  let assert Ok(s) = dict.get(p2.body, "loop_1")
  s.live_before
  |> should.equal(set.from_list([LocVar("sum.1"), LocVar("i.2"), LocReg(Rsp)]))
  // X86Program(
  //   dict.from_list([
  //     #(
  //       "block_1",
  //       Block(
  //         [Movq(Var("sum.1"), Reg(Rax)), Jmp("conclusion")],
  //         Set(dict.from_list([])),
  //         [],
  //       ),
  //     ),
  //     #(
  //       "block_2",
  //       Block(
  //         [
  //           Movq(Var("sum.1"), Var("tmp.2")),    [sum.1, i.2, rsp]
  //           Movq(Var("i.2"), Var("tmp.3")),      [i.2, tmp.2, rsp]
  //           Movq(Var("tmp.2"), Var("sum.1")),    [tmp.2, tmp.3, rsp]
  //           Addq(Var("tmp.3"), Var("sum.1")),    [i.2, tmp.3, rsp]
  //           Movq(Var("i.2"), Var("tmp.4")),      [i.2, sum.1, rsp]
  //           Movq(Var("tmp.4"), Var("i.2")),      [tmp.4, sum.1, rsp]
  //           Subq(Imm(1), Var("i.2")),            [sum.1, rsp]
  //           Jmp("loop_1"),                       [sum.1, i.2, rsp]
  //         ],
  //         Set(dict.from_list([])),
  //         [],
  //       ),
  //     ),
  //     #(
  //       "loop_1",
  //       Block(
  //         [
  //           Movq(Var("i.2"), Var("tmp.1")),
  //           Cmpq(Imm(0), Var("tmp.1")),
  //           JmpIf(G, "block_2"),
  //           Jmp("block_1"),
  //         ],
  //         Set(dict.from_list([])),
  //         [],
  //       ),
  //     ),
  //     #(
  //       "start",
  //       Block(
  //         [Movq(Imm(0), Var("sum.1")), Movq(Imm(5), Var("i.2")), Jmp("loop_1")],
  //         Set(dict.from_list([])),
  //         [],
  //       ),
  //     ),
  //   ]),
  //   Graph(
  //     Graph(
  //       dict.from_list([
  //         #(
  //           LocReg(R10),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R10),
  //               Node(LocReg(R10), Some(6), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R11),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R11),
  //               Node(LocReg(R11), Some(-4), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R12),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R12),
  //               Node(LocReg(R12), Some(8), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R13),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R13),
  //               Node(LocReg(R13), Some(9), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R14),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R14),
  //               Node(LocReg(R14), Some(10), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R15),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R15),
  //               Node(LocReg(R15), Some(-5), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R8),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R8),
  //               Node(LocReg(R8), Some(4), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(R9),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(R9),
  //               Node(LocReg(R9), Some(5), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rax),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rax),
  //               Node(LocReg(Rax), Some(-1), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rbp),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rbp),
  //               Node(LocReg(Rbp), Some(-3), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rbx),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rbx),
  //               Node(LocReg(Rbx), Some(7), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rcx),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rcx),
  //               Node(LocReg(Rcx), Some(0), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rdi),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rdi),
  //               Node(LocReg(Rdi), Some(3), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rdx),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rdx),
  //               Node(LocReg(Rdx), Some(1), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rsi),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rsi),
  //               Node(LocReg(Rsi), Some(2), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //         #(
  //           LocReg(Rsp),
  //           Context(
  //             dict.from_list([]),
  //             Node(
  //               LocReg(Rsp),
  //               Node(LocReg(Rsp), Some(-2), Set(dict.from_list([]))),
  //             ),
  //           ),
  //         ),
  //       ]),
  //     ),
  //   ),
  // )
}

fn parsed(input: String) -> l.Program {
  input
  |> tokens
  |> should.be_ok
  |> parse
  |> should.be_ok
}
