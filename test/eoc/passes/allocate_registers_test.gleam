import birdie
import eoc/langs/l_fun as l
import eoc/langs/x86_base.{G, L, LocReg, LocVar, Rax, Rcx, Rdx, Rsi, Rsp}
import eoc/langs/x86_def_callq.{
  Addq, Block, Callq, Cmpq, Imm, Jmp, JmpIf, Movq, Negq, Reg, Var, X86Program,
} as x86
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
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
    Jmp("main_conclusion"),
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

  let types =
    dict.from_list([
      #("v", l.IntegerT),
      #("w", l.IntegerT),
      #("x", l.IntegerT),
      #("y", l.IntegerT),
      #("z", l.IntegerT),
      #("t", l.IntegerT),
    ])

  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #("start", Block(..base_block, body: instrs, live_after:)),
      ]),
      types:,
    )

  let p =
    X86Program([main])
    |> build_interference.build_interference()

  let instrs2 = [
    x86.Movq(x86.Imm(1), x86.Reg(Rdx)),
    x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
    x86.Movq(x86.Reg(Rdx), x86.Reg(Rdx)),
    x86.Addq(x86.Imm(7), x86.Reg(Rdx)),
    x86.Movq(x86.Reg(Rdx), x86.Reg(Rsi)),
    x86.Movq(x86.Reg(Rdx), x86.Reg(Rdx)),
    x86.Addq(x86.Reg(Rcx), x86.Reg(Rdx)),
    x86.Movq(x86.Reg(Rsi), x86.Reg(Rcx)),
    x86.Negq(x86.Reg(Rcx)),
    x86.Movq(x86.Reg(Rdx), x86.Reg(Rax)),
    x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Jmp("main_conclusion"),
  ]

  let assert X86Program([p2]) = allocate_registers.allocate_registers(p)

  assert p2.types == main.types
  assert p2.stack_vars == 0
  assert p2.used_callee == set.new()
  assert p2.root_stack_size == 0

  let assert Ok(start_block) = dict.get(p2.blocks, "start")

  assert start_block.body == instrs2
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
    Jmp("main_conclusion"),
  ]
  let b_then = [Movq(Imm(1), Reg(Rax)), Jmp("main_conclusion")]
  let b_else = [Movq(Imm(2), Reg(Rax)), Jmp("main_conclusion")]
  let types =
    dict.from_list([
      #("a", l.IntegerT),
      #("b", l.IntegerT),
      #("c", l.IntegerT),
      #("d", l.IntegerT),
    ])

  let block = x86.new_block()
  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #("start", Block(..block, body: start)),
        #("a_then", Block(..block, body: a_then)),
        #("a_else", Block(..block, body: a_else)),
        #("b_then", Block(..block, body: b_then)),
        #("b_else", Block(..block, body: b_else)),
      ]),
      types:,
    )
  let p = X86Program([main])

  let assert X86Program([main2]) =
    p
    |> uncover_live.uncover_live
    |> build_interference.build_interference
    |> allocate_registers.allocate_registers

  let assert Ok(start) = dict.get(main2.blocks, "start")
  let start_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(x86_base.Rbx)),
    x86.Cmpq(x86.Imm(10), x86.Reg(x86_base.Rbx)),
    x86.JmpIf(G, "a_then"),
    x86.Jmp("a_else"),
  ]
  assert start.body == start_expected

  let assert Ok(a_then) = dict.get(main2.blocks, "a_then")
  let a_then_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Cmpq(x86.Reg(x86_base.Rbx), x86.Reg(Rcx)),
    x86.JmpIf(L, "b_then"),
    x86.Jmp("b_else"),
  ]
  assert a_then.body == a_then_expected

  let assert Ok(a_else) = dict.get(main2.blocks, "a_else")
  let a_else_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(x86_base.Rbx)),
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Addq(x86.Reg(x86_base.Rbx), x86.Reg(Rcx)),
    x86.Movq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Jmp("main_conclusion"),
  ]
  assert a_else.body == a_else_expected
}

pub fn allocate_registers_vectors_test() {
  let p =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses

  let assert X86Program([main]) = allocate_registers.allocate_registers(p)
  assert main.root_stack_size == 1
}

pub fn allocate_registers_vectors_multiple_roots_test() {
  let p =
    "
    (let ([a (vector 42)])
      (let ([b (vector a)])
         (+ (vector-ref (vector-ref (vector a) 0) 0)
            (vector-ref (vector-ref b 0) 0)
         )
      )
    )
  "
    |> parsed
    |> prepasses()

  let assert X86Program([main]) = allocate_registers.allocate_registers(p)
  assert main.root_stack_size == 3
}

pub fn allocate_registers_functions_test() {
  let p =
    "
  (define (inc [x : Integer]) : Integer
    (+ x 1))

  (inc 41)
  "
    |> parsed
    |> prepasses

  allocate_registers.allocate_registers(p).defs
  |> list.map(fn(d) {
    #(d.label, dict.map_values(d.blocks, fn(_, b) { b.body }))
  })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "allocate_registers_functions_test blocks")
}

pub fn allocate_registers_multiple_functions_test() {
  let p =
    "
  (define (map [f : (Integer -> Integer)] [v : (Vector Integer Integer)]) : (Vector Integer Integer)
    (vector (f (vector-ref v 0)) (f (vector-ref v 1))))

  (define (inc [x : Integer]) : Integer
    (+ x 1))

  (vector-ref (map inc (vector 0 41)) 1)
  "
    |> parsed()
    |> prepasses()

  allocate_registers.allocate_registers(p).defs
  |> list.map(fn(d) {
    #(
      d.label,
      #(
        dict.map_values(d.blocks, fn(_, b) { b.body }),
        d.root_stack_size,
        d.stack_vars,
      ),
    )
  })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "allocate_registers_multiple_functions_test blocks")
}

fn parsed(input: String) -> l.Program {
  let assert Ok(toks) = parse.tokens(input)
  let assert Ok(ast) = parse.parse(toks)
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
  |> uncover_live.uncover_live
  |> build_interference.build_interference
}
