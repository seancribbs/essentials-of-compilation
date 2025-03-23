import eoc/langs/c_var as c
import eoc/langs/l_var
import eoc/langs/x86_var as x86
import eoc/passes/explicate_control
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions.{select_instructions}
import eoc/passes/uniquify
import gleam/dict
import gleeunit/should

pub fn select_instructions_test() {
  let c =
    c.Seq(
      c.Assign("x.2", c.Atom(c.Int(20))),
      c.Seq(
        c.Assign("x.1", c.Atom(c.Int(22))),
        c.Seq(
          c.Assign("y.3", c.Prim(c.Plus(c.Variable("x.2"), c.Variable("x.1")))),
          c.Return(c.Atom(c.Variable("y.3"))),
        ),
      ),
    )

  let cp = c.CProgram(dict.new(), dict.from_list([#("start", c)]))

  let x =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(20), x86.Var("x.2")),
            x86.Movq(x86.Imm(22), x86.Var("x.1")),
            x86.Movq(x86.Var("x.2"), x86.Var("y.3")),
            x86.Addq(x86.Var("x.1"), x86.Var("y.3")),
            x86.Movq(x86.Var("y.3"), x86.Reg(x86.Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  cp |> select_instructions() |> should.equal(x)
}

// (+ 42 (- 10))
pub fn select_instructions_neg_test() {
  let cp =
    l_var.Program(
      l_var.Prim(l_var.Plus(
        l_var.Int(42),
        l_var.Prim(l_var.Negate(l_var.Int(10))),
      )),
    )
    |> uniquify.uniquify()
    |> remove_complex_operands.remove_complex_operands()
    |> explicate_control.explicate_control()

  let x =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block([
            x86.Movq(x86.Imm(10), x86.Var("tmp.1")),
            x86.Negq(x86.Var("tmp.1")),
            x86.Movq(x86.Imm(42), x86.Reg(x86.Rax)),
            x86.Addq(x86.Var("tmp.1"), x86.Reg(x86.Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  cp |> select_instructions() |> should.equal(x)
}
