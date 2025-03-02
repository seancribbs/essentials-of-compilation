// import gleeunit
import gleeunit/should
import langs/l_var.{Int, Let, Plus, Prim, Program, Var}
import passes/uniquify.{uniquify}

// (let ([x 32]) (+ let ([x 10]) x) x)
// (let ([x.1 32]) (+ let ([x.2 10]) x.2) x.1)
pub fn uniquify_test() {
  let p =
    Program(Let("x", Int(32), Prim(Plus(Let("x", Int(10), Var("x")), Var("x")))))

  let p1 =
    Program(Let(
      "x.1",
      Int(32),
      Prim(Plus(Let("x.2", Int(10), Var("x.2")), Var("x.1"))),
    ))

  p |> uniquify() |> should.equal(p1)
}

// (let ([x (let ([x 4]) (+ x 1))]) (+ x 2))
// (let ([x.2 (let ([x.1 4]) (+ x.1 1))]) (+ x.2 2))
pub fn uniquify_inner_let_test() {
  let p =
    Program(Let(
      "x",
      Let("x", Int(4), Prim(Plus(Var("x"), Int(1)))),
      Prim(Plus(Var("x"), Int(2))),
    ))

  let p1 =
    Program(Let(
      "x.2",
      Let("x.1", Int(4), Prim(Plus(Var("x.1"), Int(1)))),
      Prim(Plus(Var("x.2"), Int(2))),
    ))

  p |> uniquify() |> should.equal(p1)
}
