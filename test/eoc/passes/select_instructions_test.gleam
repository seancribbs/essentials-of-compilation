import eoc/langs/c_tup as c
import eoc/passes/expose_allocation
import eoc/passes/shrink
import eoc/passes/uncover_get

import eoc/langs/l_tup as l
import eoc/langs/x86_base.{Rax}
import eoc/langs/x86_global as x86

import eoc/passes/explicate_control
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions.{select_instructions}
import eoc/passes/uniquify

import gleam/dict
import gleam/list
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
  let base_program = x86.new_program()
  let x =
    x86.X86Program(
      ..base_program,
      body: dict.from_list([
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
      types: dict.from_list([
        #("x.2", l.IntegerT),
        #("x.1", l.IntegerT),
        #("y.3", l.IntegerT),
      ]),
    )

  cp |> select_instructions() |> should.equal(x)
}

// (+ 42 (- 10))
pub fn select_instructions_neg_test() {
  // True |> should.equal(True)
  let cp =
    l.Program(l.Prim(l.Plus(l.Int(42), l.Prim(l.Negate(l.Int(10))))))
    |> prepasses

  let base_block = x86.new_block()
  let base_program = x86.new_program()

  let x =
    x86.X86Program(
      ..base_program,
      body: dict.from_list([
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
      types: dict.from_list([#("tmp.1", l.IntegerT)]),
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
              c.Prim(c.Cmp(l.Eq, c.Variable("tmp.1"), c.Int(0))),
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
              c.Prim(c.Cmp(l.Eq, c.Variable("tmp.2"), c.Int(1))),
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
  let base_program = x86.new_program()

  let p2 =
    x86.X86Program(
      ..base_program,
      body: dict.from_list([
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
      types: dict.from_list([#("tmp.1", l.IntegerT), #("tmp.2", l.IntegerT)]),
    )

  // let p1 = select_instructions(p)
  // dict.each(p2.body, fn(block_name, block2) {
  //   let block1 = p1.body |> dict.get(block_name) |> should.be_ok
  //   block1.body |> should.equal(block2.body)
  // })
  p |> select_instructions |> should.equal(p2)
}

pub fn select_instructions_void_test() {
  let p =
    "
    (let ([x (void)])
      5)
      "
    |> parsed
    |> prepasses

  let base_block = x86.new_block()
  let base_program = x86.new_program()
  let p2 =
    x86.X86Program(
      ..base_program,
      body: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Movq(x86.Imm(0), x86.Var("x.1")),
            x86.Movq(x86.Imm(5), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      types: dict.from_list([#("x.1", l.VoidT)]),
    )

  p |> select_instructions |> should.equal(p2)
}

pub fn select_instructions_read_stmt_test() {
  let p =
    "
    (let ([x (begin (read) 2)])
      5)
      "
    |> parsed
    |> prepasses

  let base_block = x86.new_block()
  let base_program = x86.new_program()
  let p2 =
    x86.X86Program(
      ..base_program,
      body: dict.from_list([
        #(
          "start",
          x86.Block(..base_block, body: [
            x86.Callq("read_int", 0),
            x86.Movq(x86.Imm(2), x86.Var("x.1")),
            x86.Movq(x86.Imm(5), x86.Reg(Rax)),
            x86.Jmp("conclusion"),
          ]),
        ),
      ]),
      types: dict.from_list([#("x.1", l.IntegerT)]),
    )

  p |> select_instructions |> should.equal(p2)
}

pub fn select_instructions_compute_tag_test() {
  select_instructions.compute_tag(1, l.VectorT([l.VectorT([l.IntegerT])]))
  |> should.equal(0b10000010)

  select_instructions.compute_tag(1, l.VectorT([l.IntegerT]))
  |> should.equal(0b00000010)

  select_instructions.compute_tag(
    3,
    l.VectorT([l.IntegerT, l.VectorT([l.BooleanT]), l.IntegerT]),
  )
  |> should.equal(0b0100000110)

  select_instructions.compute_tag(
    5,
    l.VectorT([
      l.IntegerT,
      l.VectorT([l.BooleanT]),
      l.IntegerT,
      l.VectorT([l.BooleanT]),
      l.VectorT([l.BooleanT]),
    ]),
  )
  |> should.equal(0b110100001010)
}

pub fn select_instructions_tuple_test() {
  let p =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses

  let x86.X86Program(blocks, types, _) = select_instructions(p)

  let assert Ok(x86.Block(body:, live_before: _, live_after: _)) =
    dict.get(blocks, "block_1")
  let expected = [
    x86.Movq(x86.Global("free_ptr"), x86.Reg(x86_base.R11)),
    x86.Addq(x86.Imm(16), x86.Global("free_ptr")),
    x86.Movq(x86.Imm(0b10000010), x86.Deref(x86_base.R11, 0)),
    x86.Movq(x86.Reg(x86_base.R11), x86.Var("alloc6")),
  ]
  body |> list.take(4) |> should.equal(expected)

  types
  |> dict.get("alloc6")
  |> should.be_ok()
  |> should.equal(l.VectorT([l.VectorT([l.IntegerT])]))

  types
  |> dict.get("alloc2")
  |> should.be_ok()
  |> should.equal(l.VectorT([l.IntegerT]))

  types
  |> dict.get("tmp.8")
  |> should.be_ok()
  |> should.equal(l.VectorT([l.IntegerT]))
}

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens
  |> should.be_ok
  |> parse.parse
  |> should.be_ok
}

fn prepasses(input: l.Program) -> c.CProgram {
  input
  |> l.type_check_program
  |> should.be_ok
  |> shrink.shrink
  |> uniquify.uniquify
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control.explicate_control
}
