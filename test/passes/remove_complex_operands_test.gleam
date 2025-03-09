// import gleeunit
import gleeunit/should
import langs/l_mon_var
import langs/l_var
import passes/remove_complex_operands.{remove_complex_operands}

// (+ 42 (- 10))
//
// rco_atom: (- 10) => #(Var("tmp.1"), %{ "tmp.1" => Neg(Int(10)) })
//
// (let ([tmp.1 (- 10)])
//    (+ 42 tmp.1))
pub fn rco_test() {
  let p =
    l_var.Program(
      l_var.Prim(l_var.Plus(
        l_var.Int(42),
        l_var.Prim(l_var.Negate(l_var.Int(10))),
      )),
    )

  let p2 =
    l_mon_var.Program(l_mon_var.Let(
      "tmp.1",
      l_mon_var.Prim(l_mon_var.Negate(l_mon_var.Int(10))),
      l_mon_var.Prim(l_mon_var.Plus(l_mon_var.Int(42), l_mon_var.Var("tmp.1"))),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}

// (let ([a 42])
//    (let ([b a])
//      b))
pub fn rco_noop_test() {
  let p =
    l_var.Program(l_var.Let(
      "a",
      l_var.Int(42),
      l_var.Let("b", l_var.Var("a"), l_var.Var("b")),
    ))

  let p2 =
    l_mon_var.Program(l_mon_var.Let(
      "a",
      l_mon_var.Atomic(l_mon_var.Int(42)),
      l_mon_var.Let(
        "b",
        l_mon_var.Atomic(l_mon_var.Var("a")),
        l_mon_var.Atomic(l_mon_var.Var("b")),
      ),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}
