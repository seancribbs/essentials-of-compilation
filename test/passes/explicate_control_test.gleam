import gleam/dict
import gleeunit/should
import passes/explicate_control.{explicate_control}

import langs/c_var as c
import langs/l_mon_var as lmv

pub fn explicate_control_test() {
  let p =
    lmv.Program(lmv.Let(
      "y.3",
      lmv.Let(
        "x.2",
        lmv.Atomic(lmv.Int(20)),
        lmv.Let(
          "x.1",
          lmv.Atomic(lmv.Int(22)),
          lmv.Prim(lmv.Plus(lmv.Var("x.2"), lmv.Var("x.1"))),
        ),
      ),
      lmv.Atomic(lmv.Var("y.3")),
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
