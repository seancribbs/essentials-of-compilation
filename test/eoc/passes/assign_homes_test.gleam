import eoc/langs/x86_int as x86
import eoc/langs/x86_var as var
import eoc/passes/assign_homes
import gleam/dict
import gleeunit/should

pub fn assign_homes_test() {
  let vp =
    var.X86Program(
      dict.from_list([
        #(
          "start",
          var.Block([
            var.Movq(var.Imm(20), var.Var("x.2")),
            var.Movq(var.Imm(22), var.Var("x.1")),
            var.Movq(var.Var("x.2"), var.Var("y.3")),
            var.Addq(var.Var("x.1"), var.Var("y.3")),
            var.Movq(var.Var("y.3"), var.Reg(var.Rax)),
            var.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  let xp =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(20), x86.Deref(x86.Rbp, -8)),
              x86.Movq(x86.Imm(22), x86.Deref(x86.Rbp, -16)),
              x86.Movq(x86.Deref(x86.Rbp, -8), x86.Deref(x86.Rbp, -24)),
              x86.Addq(x86.Deref(x86.Rbp, -16), x86.Deref(x86.Rbp, -24)),
              x86.Movq(x86.Deref(x86.Rbp, -24), x86.Reg(x86.Rax)),
              x86.Jmp("conclusion"),
            ],
            24,
          ),
        ),
      ]),
    )

  vp |> assign_homes.assign_homes() |> should.equal(xp)
}

pub fn assign_homes_neg_test() {
  let vp =
    var.X86Program(
      dict.from_list([
        #(
          "start",
          var.Block([
            var.Movq(var.Imm(10), var.Var("tmp.1")),
            var.Negq(var.Var("tmp.1")),
            var.Movq(var.Imm(42), var.Reg(var.Rax)),
            var.Addq(var.Var("tmp.1"), var.Reg(var.Rax)),
            var.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  let xp =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(
            [
              x86.Movq(x86.Imm(10), x86.Deref(x86.Rbp, -8)),
              x86.Negq(x86.Deref(x86.Rbp, -8)),
              x86.Movq(x86.Imm(42), x86.Reg(x86.Rax)),
              x86.Addq(x86.Deref(x86.Rbp, -8), x86.Reg(x86.Rax)),
              x86.Jmp("conclusion"),
            ],
            8,
          ),
        ),
      ]),
    )
  vp |> assign_homes.assign_homes() |> should.equal(xp)
}
