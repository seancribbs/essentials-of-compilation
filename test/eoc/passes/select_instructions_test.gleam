import birdie
import eoc/langs/c_fun as c
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uncover_get
import pprint

import eoc/langs/l_fun as l
import eoc/langs/x86_base.{Rax}
import eoc/langs/x86_def_callq as x86

import eoc/passes/explicate_control
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions.{select_instructions}
import eoc/passes/uniquify

import gleam/dict
import gleam/list

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

  let cp =
    c.CProgram(dict.new(), [
      c.Definition(
        name: "main",
        arguments: [],
        return: l.IntegerT,
        body: c.Blocks(dict.from_list([#("start", c)]), "main"),
      ),
    ])

  let base_block = x86.new_block()
  let base_definition = x86.new_definition()
  let blocks =
    dict.from_list([
      #(
        "start",
        x86.Block(..base_block, body: [
          x86.Movq(x86.Imm(20), x86.Var("x.2")),
          x86.Movq(x86.Imm(22), x86.Var("x.1")),
          x86.Movq(x86.Var("x.2"), x86.Var("y.3")),
          x86.Addq(x86.Var("x.1"), x86.Var("y.3")),
          x86.Movq(x86.Var("y.3"), x86.Reg(Rax)),
          x86.Jmp("main_conclusion"),
        ]),
      ),
    ])
  let types =
    dict.from_list([
      #("x.2", l.IntegerT),
      #("x.1", l.IntegerT),
      #("y.3", l.IntegerT),
    ])
  let x =
    x86.X86Program([
      x86.Definition(
        ..base_definition,
        label: "main",
        return: l.IntegerT,
        blocks:,
        types:,
      ),
    ])

  assert select_instructions(cp) == x
}

// (+ 42 (- 10))
pub fn select_instructions_neg_test() {
  // True |> should.equal(True)
  let cp =
    l.ProgramDefsExp([], l.Prim(l.Plus(l.Int(42), l.Prim(l.Negate(l.Int(10))))))
    |> prepasses

  let base_block = x86.new_block()
  let base_definition = x86.new_definition()

  let x =
    x86.X86Program([
      x86.Definition(
        ..base_definition,
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([
          #(
            "main",
            x86.Block(..base_block, body: [
              x86.Movq(x86.Imm(10), x86.Var("tmp.1")),
              x86.Negq(x86.Var("tmp.1")),
              x86.Movq(x86.Imm(42), x86.Reg(Rax)),
              x86.Addq(x86.Var("tmp.1"), x86.Reg(Rax)),
              x86.Jmp("main_conclusion"),
            ]),
          ),
        ]),
        types: dict.from_list([#("tmp.1", l.IntegerT)]),
      ),
    ])

  assert select_instructions(cp) == x
}

pub fn select_instructions_branches_test() {
  let p =
    c.CProgram(dict.new(), [
      c.Definition(
        name: "main",
        arguments: [],
        return: l.IntegerT,
        body: c.Blocks(
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
          "main",
        ),
      ),
    ])

  let base_block = x86.new_block()
  let base_definition = x86.new_definition()

  let p2 =
    x86.X86Program([
      x86.Definition(
        ..base_definition,
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([
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
              x86.Jmp("main_conclusion"),
            ]),
          ),
          #(
            "block_2",
            x86.Block(..base_block, body: [
              x86.Movq(x86.Imm(42), x86.Reg(Rax)),
              x86.Jmp("main_conclusion"),
            ]),
          ),
        ]),
        types: dict.from_list([#("tmp.1", l.IntegerT), #("tmp.2", l.IntegerT)]),
      ),
    ])

  // let p1 = select_instructions(p)
  // dict.each(p2.body, fn(block_name, block2) {
  //   let block1 = p1.body |> dict.get(block_name) |> should.be_ok
  //   block1.body |> should.equal(block2.body)
  // })
  assert select_instructions(p) == p2
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
  let base_definition = x86.new_definition()

  let p2 =
    x86.X86Program([
      x86.Definition(
        ..base_definition,
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([
          #(
            "main",
            x86.Block(..base_block, body: [
              x86.Movq(x86.Imm(0), x86.Var("x.1")),
              x86.Movq(x86.Imm(5), x86.Reg(Rax)),
              x86.Jmp("main_conclusion"),
            ]),
          ),
        ]),
        types: dict.from_list([#("x.1", l.VoidT)]),
      ),
    ])

  assert select_instructions(p) == p2
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
  let base_definition = x86.new_definition()

  let p2 =
    x86.X86Program([
      x86.Definition(
        ..base_definition,
        label: "main",
        return: l.IntegerT,
        blocks: dict.from_list([
          #(
            "main",
            x86.Block(..base_block, body: [
              x86.Callq("read_int", 0),
              x86.Movq(x86.Imm(2), x86.Var("x.1")),
              x86.Movq(x86.Imm(5), x86.Reg(Rax)),
              x86.Jmp("main_conclusion"),
            ]),
          ),
        ]),
        types: dict.from_list([#("x.1", l.IntegerT)]),
      ),
    ])

  assert select_instructions(p) == p2
}

pub fn select_instructions_compute_tag_test() {
  assert select_instructions.compute_tag(
      1,
      l.VectorT([l.VectorT([l.IntegerT])]),
    )
    == 0b10000010

  assert select_instructions.compute_tag(1, l.VectorT([l.IntegerT]))
    == 0b00000010

  assert select_instructions.compute_tag(
      3,
      l.VectorT([l.IntegerT, l.VectorT([l.BooleanT]), l.IntegerT]),
    )
    == 0b0100000110

  assert select_instructions.compute_tag(
      5,
      l.VectorT([
        l.IntegerT,
        l.VectorT([l.BooleanT]),
        l.IntegerT,
        l.VectorT([l.BooleanT]),
        l.VectorT([l.BooleanT]),
      ]),
    )
    == 0b110100001010
}

pub fn select_instructions_tuple_test() {
  let p =
    "(vector-ref (vector-ref (vector (vector 42)) 0) 0)"
    |> parsed
    |> prepasses

  let assert x86.X86Program([x86.Definition(blocks:, types:, ..)]) =
    select_instructions(p)

  let assert Ok(x86.Block(body:, live_before: _, live_after: _)) =
    dict.get(blocks, "main_block_1")
  let expected = [
    x86.Movq(x86.Global("free_ptr"), x86.Reg(x86_base.R11)),
    x86.Addq(x86.Imm(16), x86.Global("free_ptr")),
    x86.Movq(x86.Imm(0b10000010), x86.Deref(x86_base.R11, 0)),
    x86.Movq(x86.Reg(x86_base.R11), x86.Var("alloc6")),
  ]
  assert list.take(body, 4) == expected

  let assert Ok(value) = dict.get(types, "alloc6")
  assert value == l.VectorT([l.VectorT([l.IntegerT])])

  let assert Ok(value) = dict.get(types, "alloc2")
  assert value == l.VectorT([l.IntegerT])

  let assert Ok(value) = dict.get(types, "tmp.8")
  assert value == l.VectorT([l.IntegerT])
}

pub fn select_instructions_call_test() {
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

  // funref -> leaq
  //  - map and inc in "main" are put into variables with leaq
  // moving things to/from argument registers
  //  - call to "map" in "main" receives two arguments
  //  - two calls in "map" that receive one argument
  // capturing return values from %rax
  //  - "main" copies the result of calling "map" in a variable
  //  - "map" copies the result of calling "f" twice into variables

  select_instructions(p).defs
  |> list.map(fn(d) { #(d.label, d.blocks) })
  |> dict.from_list()
  |> pprint.format()
  |> birdie.snap(title: "select_instructions_call_test function blocks")
}

pub fn select_instructions_tail_call_test() {
  let p =
    "
  (define (inc [x : Integer]) : Integer
    (+ x 1))

  (inc 41)
  "
    |> parsed()
    |> prepasses()
    |> select_instructions()

  let assert Ok(x86.Definition(blocks: main_blocks, ..)) =
    list.find(p.defs, fn(d) { d.label == "main" })
  let assert Ok(x86.Definition(blocks: inc_blocks, ..)) =
    list.find(p.defs, fn(d) { d.label == "inc" })
  let assert Ok(main) = dict.get(main_blocks, "main")
  let assert Ok(inc) = dict.get(inc_blocks, "inc")

  // indirect calls vs. tail cails
  // - "main" puts "inc" into a variable
  // - "main" puts one argument into registers before calling "inc"
  // - "main" tailcalls -> tailjmp

  let assert [
    x86.Leaq(x86.Global("inc"), lvar),
    x86.Movq(x86.Imm(41), x86.Reg(x86_base.Rdi)),
    x86.TailJmp(fvar, 1),
  ] = main.body
  assert lvar == fvar

  let assert [
    x86.Movq(x86.Reg(x86_base.Rdi), x),
    x86.Movq(x1, rax),
    x86.Addq(x86.Imm(1), rax1),
    x86.Jmp("inc_conclusion"),
  ] = inc.body
  assert x == x1
  assert rax == rax1
}

fn parsed(input: String) -> l.Program {
  let assert Ok(tokens) = parse.tokens(input)
  let assert Ok(untyped) = parse.parse(tokens)
  untyped
}

fn prepasses(input: l.Program) -> c.CProgram {
  let assert Ok(ast) = l.type_check_program(input)
  ast
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
  |> limit_functions.limit_functions
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control.explicate_control
}
