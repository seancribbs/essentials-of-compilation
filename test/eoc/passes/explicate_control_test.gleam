import eoc/passes/explicate_control.{explicate_control}
import eoc/passes/parse
import eoc/passes/remove_complex_operands
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uniquify
import gleam/dict
import gleeunit/should

import eoc/langs/c_loop as c
import eoc/langs/l_mon_while as l_mon
import eoc/langs/l_while.{Eq, Lt} as l

pub fn explicate_control_test() {
  let p =
    l_mon.Program(l_mon.Let(
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
    ))

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

  p
  |> explicate_control()
  |> should.equal(cp)
}

pub fn explicate_control_if_test() {
  let p =
    l_mon.Program(l_mon.Let(
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
    ))

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("x", c.Prim(c.Read)),
            c.Seq(
              c.Assign("y", c.Prim(c.Read)),
              c.If(
                c.Prim(c.Cmp(Lt, c.Variable("x"), c.Int(1))),
                c.Goto("block_3"),
                c.Goto("block_4"),
              ),
            ),
          ),
        ),
        #(
          "block_3",
          c.If(
            c.Prim(c.Cmp(Eq, c.Variable("x"), c.Int(0))),
            c.Goto("block_1"),
            c.Goto("block_2"),
          ),
        ),
        #(
          "block_4",
          c.If(
            c.Prim(c.Cmp(Eq, c.Variable("x"), c.Int(2))),
            c.Goto("block_1"),
            c.Goto("block_2"),
          ),
        ),
        #("block_1", c.Return(c.Prim(c.Plus(c.Variable("y"), c.Int(2))))),
        #("block_2", c.Return(c.Prim(c.Plus(c.Variable("y"), c.Int(10))))),
      ]),
    )

  p |> explicate_control |> should.equal(p2)
}

pub fn explicate_control_eliminate_constant_conditions_test() {
  // (if #t 1 2) =>
  // return 1
  let p =
    l_mon.Program(l_mon.If(
      l_mon.Atomic(l_mon.Bool(True)),
      l_mon.Atomic(l_mon.Int(1)),
      l_mon.Atomic(l_mon.Int(2)),
    ))

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([#("start", c.Return(c.Atom(c.Int(1))))]),
    )

  p |> explicate_control |> should.equal(p2)

  // (if (not #f) 1 2) =>
  // return 1
  let p =
    l_mon.Program(l_mon.If(
      l_mon.Prim(l_mon.Not(l_mon.Bool(False))),
      l_mon.Atomic(l_mon.Int(1)),
      l_mon.Atomic(l_mon.Int(2)),
    ))

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([#("start", c.Return(c.Atom(c.Int(1))))]),
    )

  p |> explicate_control |> should.equal(p2)
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
    l_mon.Program(l_mon.If(
      l_mon.Let(
        "x",
        l_mon.Prim(l_mon.Read),
        l_mon.Prim(l_mon.Cmp(Lt, l_mon.Var("x"), l_mon.Int(10))),
      ),
      l_mon.Atomic(l_mon.Int(1)),
      l_mon.Atomic(l_mon.Int(2)),
    ))

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("x", c.Prim(c.Read)),
            c.If(
              c.Prim(c.Cmp(Lt, c.Variable("x"), c.Int(10))),
              c.Goto("block_1"),
              c.Goto("block_2"),
            ),
          ),
        ),
        #("block_1", c.Return(c.Atom(c.Int(1)))),
        #("block_2", c.Return(c.Atom(c.Int(2)))),
      ]),
    )

  p |> explicate_control |> should.equal(p2)
}

pub fn explicate_control_shrink_conditions_test() {
  let p =
    l.Program(l.If(
      l.Prim(l.And(
        l.Prim(l.Cmp(Eq, l.Prim(l.Read), l.Int(0))),
        l.Prim(l.Cmp(Eq, l.Prim(l.Read), l.Int(1))),
      )),
      l.Int(0),
      l.Int(42),
    ))

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("tmp.1", c.Prim(c.Read)),
            c.If(
              c.Prim(c.Cmp(Eq, c.Variable("tmp.1"), c.Int(0))),
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
              c.Prim(c.Cmp(Eq, c.Variable("tmp.2"), c.Int(1))),
              c.Goto("block_1"),
              c.Goto("block_2"),
            ),
          ),
        ),
        #("block_1", c.Return(c.Atom(c.Int(0)))),
        #("block_2", c.Return(c.Atom(c.Int(42)))),
      ]),
    )

  p
  |> shrink.shrink
  |> uniquify.uniquify
  |> uncover_get.uncover_get
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control
  |> should.equal(p2)
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
    |> shrink.shrink
    |> uniquify.uniquify
    |> uncover_get.uncover_get
    |> remove_complex_operands.remove_complex_operands

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
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("x.1", c.Prim(c.Read)),
            c.Seq(
              c.Assign("tmp.1", c.Atom(c.Variable("x.1"))),
              c.Seq(
                c.Assign("x.1", c.Prim(c.Plus(c.Variable("tmp.1"), c.Int(1)))),
                c.Seq(
                  c.Assign("tmp.2", c.Atom(c.Variable("x.1"))),
                  c.Return(c.Prim(c.Plus(c.Variable("tmp.2"), c.Int(42)))),
                ),
              ),
            ),
          ),
        ),
      ]),
    )

  p |> explicate_control |> should.equal(p2)
}

pub fn explicate_control_while_test() {
  let p =
    "
  (let ([sum 0])
    (let ([i 5])
      (begin
        (while (> i 0)
          (begin
            (set! sum (+ sum i))
            (set! i (- i 1))))
        sum)))
  "
    |> parsed
    |> shrink.shrink
    |> uniquify.uniquify
    |> uncover_get.uncover_get
    |> remove_complex_operands.remove_complex_operands

  let p2 =
    c.CProgram(
      dict.new(),
      dict.from_list([
        #(
          "start",
          c.Seq(
            c.Assign("sum.1", c.Atom(c.Int(0))),
            c.Seq(c.Assign("i.2", c.Atom(c.Int(5))), c.Goto("loop_1")),
          ),
        ),
        // loop condition
        #(
          "loop_1",
          c.Seq(
            c.Assign("tmp.1", c.Atom(c.Variable("i.2"))),
            c.If(
              c.Prim(c.Cmp(l.Gt, c.Variable("tmp.1"), c.Int(0))),
              c.Goto("block_2"),
              c.Goto("block_1"),
            ),
          ),
        ),
        // exit point
        #("block_1", c.Return(c.Atom(c.Variable("sum.1")))),
        // body of loop
        #(
          "block_2",
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
                    c.Goto("loop_1"),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    )

  p |> explicate_control |> should.equal(p2)
}

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens
  |> should.be_ok
  |> parse.parse
  |> should.be_ok
}
