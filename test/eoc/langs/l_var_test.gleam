import eoc/langs/l_var.{Int, Let, Plus, Prim, Program, Var, interpret}
import gleeunit/should

pub fn interpreter_test() {
  let p =
    Program(Let(
      "x1",
      Int(32),
      Prim(Plus(Let("x2", Int(10), Var("x2")), Var("x1"))),
    ))
  p |> interpret() |> should.equal(42)
}
