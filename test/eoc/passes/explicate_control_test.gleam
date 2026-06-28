import eoc/passes/explicate_control.{explicate_control}
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uniquify
import gleam/dict

import eoc/langs/c_fun as c
import eoc/langs/l_fun.{Eq, Lt, type_check_program} as l
import eoc/langs/l_mon_funref as l_mon

pub fn explicate_control_test() {
  let p =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        l.IntegerT,
        l_mon.Let(
          "y.3",
          l_mon.Let(
            "x.2",
            l_mon.Atomic(l_mon.Int(20)),
            l_mon.Let(
              "x.1",
              l_mon.Atomic(l_mon.Int(22)),
              l_mon.Prim(l_mon.Plus(l_mon.Var("x.2"), l_mon.Var("x.1"))),
            ),
          ),
          l_mon.Atomic(l_mon.Var("y.3")),
        ),
      ),
    ])

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
        "main",
        [],
        l.IntegerT,
        c.Blocks(dict.from_list([#("main", c)]), "main"),
      ),
    ])

  assert explicate_control(p) == cp
}

pub fn explicate_control_if_test() {
  let p =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        l.IntegerT,
        l_mon.Let(
          "x",
          l_mon.Prim(l_mon.Read),
          l_mon.Let(
            "y",
            l_mon.Prim(l_mon.Read),
            l_mon.If(
              l_mon.If(
                l_mon.Prim(l_mon.Cmp(Lt, l_mon.Var("x"), l_mon.Int(1))),
                l_mon.Prim(l_mon.Cmp(Eq, l_mon.Var("x"), l_mon.Int(0))),
                l_mon.Prim(l_mon.Cmp(Eq, l_mon.Var("x"), l_mon.Int(2))),
              ),
              l_mon.Prim(l_mon.Plus(l_mon.Var("y"), l_mon.Int(2))),
              l_mon.Prim(l_mon.Plus(l_mon.Var("y"), l_mon.Int(10))),
            ),
          ),
        ),
      ),
    ])

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("x", c.Prim(c.Read)),
                c.Seq(
                  c.Assign("y", c.Prim(c.Read)),
                  c.If(
                    c.Prim(c.Cmp(Lt, c.Variable("x"), c.Int(1))),
                    c.Goto("main_block_3"),
                    c.Goto("main_block_4"),
                  ),
                ),
              ),
            ),
            #(
              "main_block_3",
              c.If(
                c.Prim(c.Cmp(Eq, c.Variable("x"), c.Int(0))),
                c.Goto("main_block_1"),
                c.Goto("main_block_2"),
              ),
            ),
            #(
              "main_block_4",
              c.If(
                c.Prim(c.Cmp(Eq, c.Variable("x"), c.Int(2))),
                c.Goto("main_block_1"),
                c.Goto("main_block_2"),
              ),
            ),
            #(
              "main_block_1",
              c.Return(c.Prim(c.Plus(c.Variable("y"), c.Int(2)))),
            ),
            #(
              "main_block_2",
              c.Return(c.Prim(c.Plus(c.Variable("y"), c.Int(10)))),
            ),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_eliminate_constant_conditions_test() {
  // (if #t 1 2) =>
  // return 1
  let p =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        l.IntegerT,
        l_mon.If(
          l_mon.Atomic(l_mon.Bool(True)),
          l_mon.Atomic(l_mon.Int(1)),
          l_mon.Atomic(l_mon.Int(2)),
        ),
      ),
    ])

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([#("main", c.Return(c.Atom(c.Int(1))))]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2

  // (if (not #f) 1 2) =>
  // return 1
  let p =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        l.IntegerT,
        l_mon.If(
          l_mon.Prim(l_mon.Not(l_mon.Bool(False))),
          l_mon.Atomic(l_mon.Int(1)),
          l_mon.Atomic(l_mon.Int(2)),
        ),
      ),
    ])

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([#("main", c.Return(c.Atom(c.Int(1))))]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_let_inside_condition_test() {
  // (if (let ([x read]) (< x 10)) 1 2)
  //
  // start:
  //  x = read
  //  if (< x 10)
  //    goto block_1;
  //  else
  //    goto block_1;
  // block_1:
  //  return 1;
  // block_2:
  //  return 2;

  let p =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        l.IntegerT,
        l_mon.If(
          l_mon.Let(
            "x",
            l_mon.Prim(l_mon.Read),
            l_mon.Prim(l_mon.Cmp(Lt, l_mon.Var("x"), l_mon.Int(10))),
          ),
          l_mon.Atomic(l_mon.Int(1)),
          l_mon.Atomic(l_mon.Int(2)),
        ),
      ),
    ])

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("x", c.Prim(c.Read)),
                c.If(
                  c.Prim(c.Cmp(Lt, c.Variable("x"), c.Int(10))),
                  c.Goto("main_block_1"),
                  c.Goto("main_block_2"),
                ),
              ),
            ),
            #("main_block_1", c.Return(c.Atom(c.Int(1)))),
            #("main_block_2", c.Return(c.Atom(c.Int(2)))),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_shrink_conditions_test() {
  let p =
    parsed(
      "
  (if (and
        (eq? (read) 0)
        (eq? (read) 1))
    0 42
  )
  ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("tmp.1", c.Prim(c.Read)),
                c.If(
                  c.Prim(c.Cmp(Eq, c.Variable("tmp.1"), c.Int(0))),
                  c.Goto("main_block_3"),
                  c.Goto("main_block_2"),
                ),
              ),
            ),
            #(
              "main_block_3",
              c.Seq(
                c.Assign("tmp.2", c.Prim(c.Read)),
                c.If(
                  c.Prim(c.Cmp(Eq, c.Variable("tmp.2"), c.Int(1))),
                  c.Goto("main_block_1"),
                  c.Goto("main_block_2"),
                ),
              ),
            ),
            #("main_block_1", c.Return(c.Atom(c.Int(0)))),
            #("main_block_2", c.Return(c.Atom(c.Int(42)))),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_begin_test() {
  let p =
    "
  (let ([x (read)])
    (begin
     (set! x (+ x 1))
     (+ x 42)))
  "
    |> parsed

  // Program(Let(
  //   "x.1",
  //   Prim(Read),
  //   Begin(
  //     [
  //       SetBang(
  //         "x.1",
  //         Let("tmp.1", GetBang("x.1"), Prim(Plus(Var("tmp.1"), Int(1)))),
  //       ),
  //     ],
  //     Let("tmp.2", GetBang("x.1"), Prim(Plus(Var("tmp.2"), Int(42)))),
  //   ),
  // ))
  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("x.1", c.Prim(c.Read)),
                c.Seq(
                  c.Assign("tmp.1", c.Atom(c.Variable("x.1"))),
                  c.Seq(
                    c.Assign(
                      "x.1",
                      c.Prim(c.Plus(c.Variable("tmp.1"), c.Int(1))),
                    ),
                    c.Seq(
                      c.Assign("tmp.2", c.Atom(c.Variable("x.1"))),
                      c.Return(c.Prim(c.Plus(c.Variable("tmp.2"), c.Int(42)))),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_while_test() {
  let p =
    parsed(
      "
  (let ([sum 0])
    (let ([i 5])
      (begin
        (while (> i 0)
          (begin
            (set! sum (+ sum i))
            (set! i (- i 1))))
        sum)))
  ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("sum.1", c.Atom(c.Int(0))),
                c.Seq(c.Assign("i.2", c.Atom(c.Int(5))), c.Goto("main_loop_1")),
              ),
            ),
            // loop condition
            #(
              "main_loop_1",
              c.Seq(
                c.Assign("tmp.1", c.Atom(c.Variable("i.2"))),
                c.If(
                  c.Prim(c.Cmp(l.Gt, c.Variable("tmp.1"), c.Int(0))),
                  c.Goto("main_block_2"),
                  c.Goto("main_block_1"),
                ),
              ),
            ),
            // exit point
            #("main_block_1", c.Return(c.Atom(c.Variable("sum.1")))),
            // body of loop
            #(
              "main_block_2",
              c.Seq(
                // get! sum.1
                c.Assign("tmp.2", c.Atom(c.Variable("sum.1"))),
                c.Seq(
                  // get! i.2
                  c.Assign("tmp.3", c.Atom(c.Variable("i.2"))),
                  c.Seq(
                    c.Assign(
                      "sum.1",
                      c.Prim(c.Plus(c.Variable("tmp.2"), c.Variable("tmp.3"))),
                    ),
                    c.Seq(
                      // get! i.2
                      c.Assign("tmp.4", c.Atom(c.Variable("i.2"))),
                      c.Seq(
                        c.Assign(
                          "i.2",
                          c.Prim(c.Minus(c.Variable("tmp.4"), c.Int(1))),
                        ),
                        c.Goto("main_loop_1"),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_vector_ref_test() {
  let p = parsed("(vector-ref (vector-ref (vector (vector 42)) 0) 0)")

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main_block_1",
              c.Seq(
                c.Assign(
                  "alloc6",
                  c.Allocate(1, l.VectorT([l.VectorT([l.IntegerT])])),
                ),
                c.Seq(
                  c.Assign(
                    "_7",
                    c.Prim(c.VectorSet(
                      c.HasType(
                        c.Variable("alloc6"),
                        l.VectorT([l.VectorT([l.IntegerT])]),
                      ),
                      c.Int(0),
                      c.Variable("vecinit5"),
                    )),
                  ),
                  c.Seq(
                    c.Assign("tmp.7", c.Atom(c.Variable("alloc6"))),
                    c.Seq(
                      c.Assign(
                        "tmp.8",
                        c.Prim(c.VectorRef(c.Variable("tmp.7"), c.Int(0))),
                      ),
                      c.Return(
                        c.Prim(c.VectorRef(
                          c.HasType(
                            c.Variable("tmp.8"),
                            l.VectorT([l.IntegerT]),
                          ),
                          c.Int(0),
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            #(
              "main_block_2",
              c.Seq(c.Assign("_8", c.Atom(c.Void)), c.Goto("main_block_1")),
            ),
            #("main_block_3", c.Seq(c.Collect(16), c.Goto("main_block_1"))),
            #(
              "main_block_4",
              c.Seq(
                c.Assign("alloc2", c.Allocate(1, l.VectorT([l.IntegerT]))),
                c.Seq(
                  c.Assign(
                    "_3",
                    c.Prim(c.VectorSet(
                      c.HasType(c.Variable("alloc2"), l.VectorT([l.IntegerT])),
                      c.Int(0),
                      c.Variable("vecinit1"),
                    )),
                  ),
                  c.Seq(
                    c.Assign("vecinit5", c.Atom(c.Variable("alloc2"))),
                    c.Seq(
                      c.Assign("tmp.4", c.GlobalValue("free_ptr")),
                      c.Seq(
                        c.Assign(
                          "tmp.5",
                          c.Prim(c.Plus(c.Variable("tmp.4"), c.Int(16))),
                        ),
                        c.Seq(
                          c.Assign("tmp.6", c.GlobalValue("fromspace_end")),
                          c.If(
                            c.Prim(c.Cmp(
                              Lt,
                              c.Variable("tmp.5"),
                              c.Variable("tmp.6"),
                            )),
                            c.Goto("main_block_2"),
                            c.Goto("main_block_3"),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            #(
              "main_block_5",
              c.Seq(c.Assign("_4", c.Atom(c.Void)), c.Goto("main_block_4")),
            ),
            #("main_block_6", c.Seq(c.Collect(16), c.Goto("main_block_4"))),
            #(
              "main",
              c.Seq(
                c.Assign("vecinit1", c.Atom(c.Int(42))),
                c.Seq(
                  c.Assign("tmp.1", c.GlobalValue("free_ptr")),
                  c.Seq(
                    c.Assign(
                      "tmp.2",
                      c.Prim(c.Plus(c.Variable("tmp.1"), c.Int(16))),
                    ),
                    c.Seq(
                      c.Assign("tmp.3", c.GlobalValue("fromspace_end")),
                      c.If(
                        c.Prim(c.Cmp(
                          Lt,
                          c.Variable("tmp.2"),
                          c.Variable("tmp.3"),
                        )),
                        c.Goto("main_block_5"),
                        c.Goto("main_block_6"),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          "main",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

pub fn explicate_control_tailcall_function_test() {
  let p =
    parsed(
      "
    (define (inc [x : Integer]) : Integer (+ x 1))
    (inc 41)
    ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("tmp.1", c.FunRef("inc", 1)),
                c.TailCall(c.Variable("tmp.1"), [c.Int(41)]),
              ),
            ),
          ]),
          "main",
        ),
      ),
      c.Definition(
        "inc",
        [#("x.1", l.IntegerT)],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #("inc", c.Return(c.Prim(c.Plus(c.Variable("x.1"), c.Int(1))))),
          ]),
          "inc",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

// TODO: Call in assign position
pub fn explicate_control_call_assign_test() {
  let p =
    parsed(
      "
    (define (inc [x : Integer]) : Integer (+ x 1))
    (let ([a (inc 40)]) (+ a 1))
    ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("tmp.1", c.FunRef("inc", 1)),
                c.Seq(
                  c.Assign("a.1", c.Call(c.Variable("tmp.1"), [c.Int(40)])),
                  c.Return(c.Prim(c.Plus(c.Variable("a.1"), c.Int(1)))),
                ),
              ),
            ),
          ]),
          "main",
        ),
      ),
      c.Definition(
        "inc",
        [#("x.2", l.IntegerT)],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #("inc", c.Return(c.Prim(c.Plus(c.Variable("x.2"), c.Int(1))))),
          ]),
          "inc",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

// TODO: Call in effect position
pub fn explicate_control_call_effect_test() {
  let p =
    parsed(
      "
      (define (inc [x : Integer]) : Integer (+ x 1))
      (begin
        (inc 1)
        42)
    ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #(
              "main",
              c.Seq(
                c.Assign("tmp.1", c.FunRef("inc", 1)),
                c.Seq(
                  c.Assign(
                    "main_apply_1",
                    c.Call(c.Variable("tmp.1"), [c.Int(1)]),
                  ),
                  c.Return(c.Atom(c.Int(42))),
                ),
              ),
            ),
          ]),
          "main",
        ),
      ),
      c.Definition(
        "inc",
        [#("x.1", l.IntegerT)],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #("inc", c.Return(c.Prim(c.Plus(c.Variable("x.1"), c.Int(1))))),
          ]),
          "inc",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

// TODO: FunRef in effect position
pub fn explicate_control_funref_effect_test() {
  let p =
    parsed(
      "
      (define (inc [x : Integer]) : Integer (+ x 1))
      (begin
        inc
        42)
    ",
    )

  let p2 =
    c.CProgram(dict.new(), [
      c.Definition(
        "main",
        [],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #("main", c.Return(c.Atom(c.Int(42)))),
          ]),
          "main",
        ),
      ),
      c.Definition(
        "inc",
        [#("x.1", l.IntegerT)],
        l.IntegerT,
        c.Blocks(
          dict.from_list([
            #("inc", c.Return(c.Prim(c.Plus(c.Variable("x.1"), c.Int(1))))),
          ]),
          "inc",
        ),
      ),
    ])

  assert explicate_control(p) == p2
}

fn parsed(input: String) -> l_mon.Program {
  let assert Ok(tokens) = parse.tokens(input)
  let assert Ok(untyped) = parse.parse(tokens)
  let assert Ok(ast) = type_check_program(untyped)
  ast
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
  |> limit_functions.limit_functions
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
}
