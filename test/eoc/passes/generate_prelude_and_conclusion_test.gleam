import eoc/langs/l_tup as l
import eoc/langs/x86_base.{Rax, Rbp, Rsp}
import eoc/langs/x86_global as x86
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation
import eoc/passes/generate_prelude_and_conclusion.{
  generate_prelude_and_conclusion,
}
import eoc/passes/parse
import eoc/passes/patch_instructions
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify
import gleam/dict
import gleam/set
import gleeunit/should

pub fn generate_prelude_and_conclusion_test() {
  let p =
    x86.X86Program(
      ..x86.new_program(),
      body: dict.from_list([
        #(
          "start",
          x86.Block(..x86.new_block(), body: [
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 3,
    )

  let p2 =
    x86.X86Program(
      ..x86.new_program(),
      body: dict.from_list([
        #(
          "main",
          x86.Block(..x86.new_block(), body: [
            x86.Pushq(x86.Reg(Rbp)),
            x86.Movq(x86.Reg(Rsp), x86.Reg(Rbp)),
            x86.Subq(x86.Imm(24), x86.Reg(Rsp)),
            x86.Jmp("start"),
          ]),
        ),
        #(
          "conclusion",
          x86.Block(..x86.new_block(), body: [
            x86.Addq(x86.Imm(24), x86.Reg(Rsp)),
            x86.Popq(x86.Reg(Rbp)),
            x86.Retq,
          ]),
        ),
        #(
          "start",
          x86.Block(..x86.new_block(), body: [
            x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
            x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
            x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
            x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
            x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      stack_vars: 3,
    )

  p |> generate_prelude_and_conclusion() |> should.equal(p2)
}

pub fn generate_allocations_test() {
  let p =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses

  p.root_stack_size |> should.equal(1)
  p.stack_vars |> should.equal(0)
  p.used_callee |> should.equal(set.new())

  let main_instrs = [
    x86.Pushq(x86.Reg(Rbp)),
    x86.Movq(x86.Reg(Rsp), x86.Reg(Rbp)),
    x86.Subq(x86.Imm(8), x86.Reg(Rsp)),
    x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rdi)),
    x86.Movq(x86.Imm(65_536), x86.Reg(x86_base.Rsi)),
    x86.Callq("initialize", 2),
    x86.Movq(x86.Global("rootstack_begin"), x86.Reg(x86_base.R15)),
    x86.Movq(x86.Imm(0), x86.Deref(x86_base.R15, 0)),
    x86.Addq(x86.Imm(8), x86.Reg(x86_base.R15)),
    x86.Jmp("start"),
  ]
  let conclusion_instrs = [
    x86.Subq(x86.Imm(8), x86.Reg(x86_base.R15)),
    x86.Addq(x86.Imm(8), x86.Reg(Rsp)),
    x86.Popq(x86.Reg(Rbp)),
    x86.Retq,
  ]

  let p2 = generate_prelude_and_conclusion(p)

  let assert Ok(x86.Block(body: main_body, ..)) = dict.get(p2.body, "main")
  main_body |> should.equal(main_instrs)

  let assert Ok(x86.Block(body: conclusion_body, ..)) =
    dict.get(p2.body, "conclusion")
  conclusion_body |> should.equal(conclusion_instrs)
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
  |> build_interference.build_interference
  |> allocate_registers.allocate_registers
  |> patch_instructions.patch_instructions
}
