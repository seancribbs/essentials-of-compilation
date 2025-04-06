import eoc/langs/x86_base.{Rax, Rbp}
import eoc/langs/x86_int as x86
import eoc/passes/patch_instructions.{patch_instructions}
import gleam/dict
import gleeunit/should

pub fn patch_instructions_test() {
  let p1 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
              x86.Movq(x86.Deref(Rbp, -8), x86.Deref(Rbp, -24)),
              x86.Addq(x86.Deref(Rbp, -16), x86.Deref(Rbp, -24)),
              x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
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
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(Rbp, -16)),
              x86.Movq(x86.Deref(Rbp, -8), x86.Reg(Rax)),
              x86.Movq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
              x86.Movq(x86.Deref(Rbp, -16), x86.Reg(Rax)),
              x86.Addq(x86.Reg(Rax), x86.Deref(Rbp, -24)),
              x86.Movq(x86.Deref(Rbp, -24), x86.Reg(Rax)),
              x86.Jmp("conclusion"),
            ],
            24,
          ),
        ),
      ]),
    )

  p1 |> patch_instructions() |> should.equal(p2)
}
