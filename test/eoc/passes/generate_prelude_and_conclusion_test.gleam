import birdie
import eoc/langs/l_fun as l
import eoc/langs/x86_base.{Rax, Rbp, Rsp}
import eoc/langs/x86_callq
import eoc/langs/x86_def_callq as x86
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/generate_prelude_and_conclusion.{
  generate_prelude_and_conclusion,
}
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/patch_instructions
import eoc/passes/remove_complex_operands
import eoc/passes/reveal_functions
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
import gleam/dict
import gleam/set
import pprint

pub fn generate_prelude_and_conclusion_test() {
  let p =
    x86.X86Program([
      x86.Definition(
        ..x86.new_definition(),
        label: "main",
        return: l.IntegerT,
        stack_vars: 3,
        blocks: dict.from_list([
          #(
            "main",
            x86.Block(..x86.new_block(), body: [
              x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
              x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
              x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
              x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
              x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
              x86.Jmp("main_conclusion"),
            ]),
          ),
        ]),
      ),
    ])

  let p2 =
    x86_callq.X86Program(
      dict.from_list([
        #(
          "main",
          x86_callq.Block(
            [
              x86_callq.Pushq(x86_callq.Reg(Rbp)),
              x86_callq.Movq(x86_callq.Reg(Rsp), x86_callq.Reg(Rbp)),
              x86_callq.Subq(x86_callq.Imm(24), x86_callq.Reg(Rsp)),
              x86_callq.Movq(x86_callq.Imm(20), x86_callq.Deref(Rbp, -8)),
              x86_callq.Movq(x86_callq.Imm(22), x86_callq.Deref(Rbp, -16)),
              x86_callq.Movq(x86_callq.Deref(Rbp, -8), x86_callq.Reg(Rax)),
              x86_callq.Movq(x86_callq.Reg(Rax), x86_callq.Deref(Rbp, -24)),
              x86_callq.Addq(
                x86_callq.Deref(Rbp, -16),
                x86_callq.Deref(Rbp, -24),
              ),
              x86_callq.Movq(x86_callq.Deref(Rbp, -24), x86_callq.Reg(Rax)),
              x86_callq.Jmp("main_conclusion"),
            ],
            True,
          ),
        ),
        #(
          "main_conclusion",
          x86_callq.Block(..x86_callq.new_block(), body: [
            x86_callq.Addq(x86_callq.Imm(24), x86_callq.Reg(Rsp)),
            x86_callq.Popq(x86_callq.Reg(Rbp)),
            x86_callq.Retq,
          ]),
        ),
      ]),
    )

  assert generate_prelude_and_conclusion(p) == p2
}

pub fn generate_allocations_test() {
  let assert x86.X86Program([main]) =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses

  assert main.root_stack_size == 1
  assert main.stack_vars == 0
  assert main.used_callee == set.from_list([x86_base.Rbx])

  let main_instrs = [
    x86_callq.Pushq(x86_callq.Reg(Rbp)),
    x86_callq.Pushq(x86_callq.Reg(x86_base.Rbx)),
    x86_callq.Movq(x86_callq.Reg(Rsp), x86_callq.Reg(Rbp)),
    x86_callq.Movq(x86_callq.Imm(65_536), x86_callq.Reg(x86_base.Rdi)),
    x86_callq.Movq(x86_callq.Imm(65_536), x86_callq.Reg(x86_base.Rsi)),
    x86_callq.Callq("initialize"),
    x86_callq.Movq(
      x86_callq.Global("rootstack_begin"),
      x86_callq.Reg(x86_base.R15),
    ),
    x86_callq.Movq(x86_callq.Imm(0), x86_callq.Deref(x86_base.R15, 0)),
    x86_callq.Addq(x86_callq.Imm(8), x86_callq.Reg(x86_base.R15)),
  ]
  let conclusion_instrs = [
    x86_callq.Subq(x86_callq.Imm(8), x86_callq.Reg(x86_base.R15)),
    x86_callq.Popq(x86_callq.Reg(x86_base.Rbx)),
    x86_callq.Popq(x86_callq.Reg(Rbp)),
    x86_callq.Retq,
  ]

  let x86_callq.X86Program(p2_blocks) =
    generate_prelude_and_conclusion(x86.X86Program([main]))

  let assert Ok(x86_callq.Block(body: main_body, ..)) =
    dict.get(p2_blocks, "main")
  assert is_prefix(main_instrs, main_body)

  let assert Ok(x86_callq.Block(body: conclusion_body, ..)) =
    dict.get(p2_blocks, "main_conclusion")
  assert conclusion_body == conclusion_instrs
}

pub fn generate_functions_test() {
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

  generate_prelude_and_conclusion(p).blocks
  |> pprint.format
  |> birdie.snap(title: "generate_functions_test blocks")
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
  |> patch_instructions.patch_instructions
}

/// Tests if a is a prefix of b
fn is_prefix(a: List(a), b: List(a)) -> Bool {
  case a, b {
    [a1, ..arest], [b1, ..brest] if a1 == b1 -> is_prefix(arest, brest)
    [], _ -> True
    _, _ -> False
  }
}
