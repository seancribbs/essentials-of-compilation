import gleeunit
import gleeunit/should
import l_var.{Int, Let, Plus, Prim, Program, Var, interpret}

pub fn main() {
  gleeunit.main()
}

pub fn interpreter_test() {
  let p =
    Program(Let(
      "x1",
      Int(32),
      Prim(Plus(Let("x2", Int(10), Var("x2")), Var("x1"))),
    ))
  p |> interpret() |> should.equal(42)
}
