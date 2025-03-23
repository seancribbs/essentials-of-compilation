import gleam/dict
import gleeunit/should
import langs/x86_int as x86
import passes/patch_instructions.{patch_instructions}

pub fn patch_instructions_test() {
  let p1 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
            x86.Movq(x86.Deref(x86.Rbp, -8), x86.Deref(x86.Rbp, -24)),
            x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
            x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  let p2 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
            x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
            x86.Movq(x86.Deref(x86.Rbp, -8), x86.Reg(x86.Rax)),
            x86.Movq(x86.Reg(x86.Rax), x86.Deref(x86.Rbp, -24)),
            x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
            x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  p1 |> patch_instructions() |> should.equal(p2)
}
