import eoc/langs/x86_int as x86
import eoc/passes/generate_prelude_and_conclusion.{
  generate_prelude_and_conclusion, program_to_text,
}
import gleam/dict
import gleam/string
import gleeunit/should

pub fn generate_prelude_and_conclusion_test() {
  let p =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
              x86.Movq(x86.Deref(x86.Rbp, -8), x86.Reg(x86.Rax)),
              x86.Movq(x86.Reg(x86.Rax), x86.Deref(x86.Rbp, -24)),
              x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
              x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
              x86.Jmp("conclusion"),
            ],
            24,
          ),
        ),
      ]),
    )

  let p2 =
    x86.X86Program(
      dict.from_list([
        #(
          "main",
          x86.Block(
            [
              x86.Pushq(x86.Reg(x86.Rbp)),
              x86.Movq(x86.Reg(x86.Rsp), x86.Reg(x86.Rbp)),
              x86.Subq(x86.Imm(24), x86.Reg(x86.Rsp)),
              x86.Jmp("start"),
            ],
            0,
          ),
        ),
        #(
          "conclusion",
          x86.Block(
            [
              x86.Addq(x86.Imm(24), x86.Reg(x86.Rsp)),
              x86.Popq(x86.Reg(x86.Rbp)),
              x86.Retq,
            ],
            0,
          ),
        ),
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
              x86.Movq(x86.Deref(x86.Rbp, -8), x86.Reg(x86.Rax)),
              x86.Movq(x86.Reg(x86.Rax), x86.Deref(x86.Rbp, -24)),
              x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
              x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
              x86.Jmp("conclusion"),
            ],
            24,
          ),
        ),
      ]),
    )

  p |> generate_prelude_and_conclusion() |> should.equal(p2)
}

pub fn program_to_text_test() {
  let p =
    x86.X86Program(
      dict.from_list([
        #(
          "main",
          x86.Block(
            [
              x86.Pushq(x86.Reg(x86.Rbp)),
              x86.Movq(x86.Reg(x86.Rsp), x86.Reg(x86.Rbp)),
              x86.Subq(x86.Imm(24), x86.Reg(x86.Rsp)),
              x86.Jmp("start"),
            ],
            0,
          ),
        ),
        #(
          "conclusion",
          x86.Block(
            [
              x86.Addq(x86.Imm(24), x86.Reg(x86.Rsp)),
              x86.Popq(x86.Reg(x86.Rbp)),
              x86.Retq,
            ],
            0,
          ),
        ),
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
              x86.Movq(x86.Deref(x86.Rbp, -8), x86.Reg(x86.Rax)),
              x86.Movq(x86.Reg(x86.Rax), x86.Deref(x86.Rbp, -24)),
              x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
              x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
              x86.Jmp("conclusion"),
            ],
            24,
          ),
        ),
      ]),
    )

  let text =
    "
conclusion:
    addq $24, %rsp
    popq %rbp
    retq

    .globl main
main:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    jmp start

start:
    movq $20, -8(%rbp)
    movq $22, -16(%rbp)
    movq -8(%rbp), %rax
    movq %rax, -24(%rbp)
    addq -16(%rbp), -24(%rbp)
    movq -24(%rbp), %rax
    jmp conclusion
"
    |> string.trim()

  p |> program_to_text("main") |> should.equal(text)
}
