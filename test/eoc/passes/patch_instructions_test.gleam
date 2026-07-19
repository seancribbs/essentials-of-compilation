import birdie
import eoc/langs/l_fun as l
import eoc/langs/x86_base.{E, Rax, Rbp, Rcx, Rsp}
import eoc/langs/x86_def_callq as x86
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/patch_instructions.{patch_instructions}
import eoc/passes/remove_complex_operands
import eoc/passes/reveal_functions
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
import gleam/dict
import gleam/list
import pprint

pub fn patch_instructions_test() {
  let base_block = x86.new_block()

  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -24)),
            x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 24,
    )

  let main2 =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 24,
    )

  assert patch_instructions(x86.X86Program([main])) == x86.X86Program([main2])
}

pub fn patch_instructions_ch3_test() {
  let base_block = x86.new_block()
  let main =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(1), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -8)),
            x86.Addq(x86.Imm(7), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -8)),
            x86.Addq(x86.Reg(Rcx), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rcx)),
            x86.Negq(x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 24,
    )

  let main2 =
    x86.Definition(
      ..x86.new_definition(),
      label: "main",
      return: l.IntegerT,
      blocks: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(1), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(42), x86.Reg(Rcx)),
            x86.Addq(x86.Imm(7), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -16)),
            x86.Addq(x86.Reg(Rcx), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rcx)),
            x86.Negq(x86.Reg(Rcx)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Addq(x86.Reg(Rcx), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 24,
    )

  assert patch_instructions(x86.X86Program([main])) == x86.X86Program([main2])
}

pub fn patch_instructions_cmp_immediate_test() {
  let base_block = x86.new_block()
  let body = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Cmpq(x86.Reg(Rcx), x86.Imm(5)),
    x86.Set(E, x86_base.Al),
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert x86.X86Program([main]) =
    x86.X86Program([
      x86.Definition(
        ..x86.new_definition(),
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([#("start", x86.Block(..base_block, body:))]),
      ),
    ])
    |> patch_instructions

  let body_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert Ok(start_block) = dict.get(main.blocks, "start")
  assert start_block.body == body_expected
}

pub fn patch_instructions_movzbq_stack_test() {
  let base_block = x86.new_block()

  let body = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    // This next instruction is invalid
    x86.Movzbq(x86_base.Al, x86.Deref(Rsp, -8)),
    x86.Movq(x86.Imm(1), x86.Reg(Rax)),
    x86.Xorq(x86.Deref(Rsp, -8), x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert x86.X86Program([main]) =
    x86.X86Program([
      x86.Definition(
        ..x86.new_definition(),
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([#("start", x86.Block(..base_block, body:))]),
      ),
    ])
    |> patch_instructions

  let body_expected = [
    x86.Callq("read_int", 0),
    x86.Movq(x86.Reg(Rax), x86.Reg(Rcx)),
    x86.Movq(x86.Imm(5), x86.Reg(Rax)),
    x86.Cmpq(x86.Reg(Rcx), x86.Reg(Rax)),
    x86.Set(E, x86_base.Al),
    // The next two instructions replace the one above
    x86.Movzbq(x86_base.Al, x86.Reg(Rax)),
    x86.Movq(x86.Reg(Rax), x86.Deref(Rsp, -8)),
    x86.Movq(x86.Imm(1), x86.Reg(Rax)),
    x86.Xorq(x86.Deref(Rsp, -8), x86.Reg(Rax)),
    x86.Jmp("conclusion"),
  ]

  let assert Ok(start_block) = dict.get(main.blocks, "start")
  assert start_block.body == body_expected
}

pub fn patch_instructions_tailjmp_test() {
  let p =
    "
  (define (inc [x : Integer]) : Integer
    (+ x 1))

  (inc 41)
  "
    |> parsed
    |> prepasses

  patch_instructions(p).defs
  |> list.map(fn(d) {
    #(d.label, dict.map_values(d.blocks, fn(_, b) { b.body }))
  })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "patch_instructions_tailjmp_test blocks")
}

pub fn patch_instructions_map_inc_test() {
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

  patch_instructions(p).defs
  |> list.map(fn(d) {
    #(d.label, dict.map_values(d.blocks, fn(_, b) { b.body }))
  })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "patch_instructions_map_inc_test blocks")
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
  |> allocate_registers.allocate_registers
}
