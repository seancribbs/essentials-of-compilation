import eoc/langs/c_if as c
import eoc/passes/shrink

import eoc/langs/l_if
import eoc/langs/x86_base.{Rax}
import eoc/langs/x86_var_if as x86

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

  let base_block = x86.new_block()

  let x =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(20), x86.Var("x.2")),
            x86.Movq(x86.Imm(22), x86.Var("x.1")),
            x86.Movq(x86.Var("x.2"), x86.Var("y.3")),
            x86.Addq(x86.Var("x.1"), x86.Var("y.3")),
            x86.Movq(x86.Var("y.3"), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  cp |> select_instructions() |> should.equal(x)
}

// (+ 42 (- 10))
pub fn select_instructions_neg_test() {
  // True |> should.equal(True)
  let cp =
    l_if.Program(
      l_if.Prim(l_if.Plus(l_if.Int(42), l_if.Prim(l_if.Negate(l_if.Int(10))))),
    )
    |> uniquify.uniquify()
    |> shrink.shrink()
    |> remove_complex_operands.remove_complex_operands()
    |> explicate_control.explicate_control()

  let base_block = x86.new_block()

  let x =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(10), x86.Var("tmp.1")),
            x86.Negq(x86.Var("tmp.1")),
            x86.Movq(x86.Imm(42), x86.Reg(Rax)),
            x86.Addq(x86.Var("tmp.1"), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  cp |> select_instructions() |> should.equal(x)
}

pub fn select_instructions_branches_test() {
  let p =
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("tmp.1", c.Prim(c.Read)),
            c.If(
              c.Prim(c.Cmp(l_if.Eq, c.Variable("tmp.1"), c.Int(0))),
              c.Goto("block_3"),
              c.Goto("block_2"),
            ),
          ),
        ),
        #(
          "block_3",
          c.Seq(
            c.Assign("tmp.2", c.Prim(c.Read)),
            c.If(
              c.Prim(c.Cmp(l_if.Eq, c.Variable("tmp.2"), c.Int(1))),
              c.Goto("block_1"),
              c.Goto("block_2"),
            ),
          ),
        ),
        #("block_1", c.Return(c.Atom(c.Int(0)))),
        #("block_2", c.Return(c.Atom(c.Int(42)))),
      ]),
    )

  let base_block = x86.new_block()

  let p2 =
    x86.X86Program(
      dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Callq("read_int", 0),
            x86.Movq(x86.Reg(Rax), x86.Var("tmp.1")),
            x86.Cmpq(x86.Imm(0), x86.Var("tmp.1")),
            x86.JmpIf(x86_base.E, "block_3"),
            x86.Jmp("block_2"),
          ]),
        ),
        #(
          "block_3",
          x86.Block(..base_block, body: [
            x86.Callq("read_int", 0),
            x86.Movq(x86.Reg(Rax), x86.Var("tmp.2")),
            x86.Cmpq(x86.Imm(1), x86.Var("tmp.2")),
            x86.JmpIf(x86_base.E, "block_1"),
            x86.Jmp("block_2"),
          ]),
        ),
        #(
          "block_1",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(0), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
        #(
          "block_2",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(42), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
    )

  // let p1 = select_instructions(p)
  // dict.each(p2.body, fn(block_name, block2) {
  //   let block1 = p1.body |> dict.get(block_name) |> should.be_ok
  //   block1.body |> should.equal(block2.body)
  // })
  p |> select_instructions |> should.equal(p2)
}
