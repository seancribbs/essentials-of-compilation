import eoc/passes/explicate_control.{explicate_control}
import eoc/passes/remove_complex_operands
import eoc/passes/shrink
import gleam/dict
import gleeunit/should

import eoc/langs/c_if as c
import eoc/langs/l_if.{Eq, Lt}
import eoc/langs/l_mon_if as lmif

pub fn explicate_control_test() {
  let p =
    lmif.Program(lmif.Let(
      "y.3",
      lmif.Let(
        "x.2",
        lmif.Atomic(lmif.Int(20)),
        lmif.Let(
          "x.1",
          lmif.Atomic(lmif.Int(22)),
          lmif.Prim(lmif.Plus(lmif.Var("x.2"), lmif.Var("x.1"))),
        ),
      ),
      lmif.Atomic(lmif.Var("y.3")),
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
    lmif.Program(lmif.Let(
      "x",
      lmif.Prim(lmif.Read),
      lmif.Let(
        "y",
        lmif.Prim(lmif.Read),
        lmif.If(
          lmif.If(
            lmif.Prim(lmif.Cmp(Lt, lmif.Var("x"), lmif.Int(1))),
            lmif.Prim(lmif.Cmp(Eq, lmif.Var("x"), lmif.Int(0))),
            lmif.Prim(lmif.Cmp(Eq, lmif.Var("x"), lmif.Int(2))),
          ),
          lmif.Prim(lmif.Plus(lmif.Var("y"), lmif.Int(2))),
          lmif.Prim(lmif.Plus(lmif.Var("y"), lmif.Int(10))),
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
    lmif.Program(lmif.If(
      lmif.Atomic(lmif.Bool(True)),
      lmif.Atomic(lmif.Int(1)),
      lmif.Atomic(lmif.Int(2)),
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
    lmif.Program(lmif.If(
      lmif.Prim(lmif.Not(lmif.Bool(False))),
      lmif.Atomic(lmif.Int(1)),
      lmif.Atomic(lmif.Int(2)),
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
    lmif.Program(lmif.If(
      lmif.Let(
        "x",
        lmif.Prim(lmif.Read),
        lmif.Prim(lmif.Cmp(Lt, lmif.Var("x"), lmif.Int(10))),
      ),
      lmif.Atomic(lmif.Int(1)),
      lmif.Atomic(lmif.Int(2)),
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
    l_if.Program(l_if.If(
      l_if.Prim(l_if.And(
        l_if.Prim(l_if.Cmp(Eq, l_if.Prim(l_if.Read), l_if.Int(0))),
        l_if.Prim(l_if.Cmp(Eq, l_if.Prim(l_if.Read), l_if.Int(1))),
      )),
      l_if.Int(0),
      l_if.Int(42),
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
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control
  |> should.equal(p2)
}
