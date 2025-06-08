// import gleeunit
import eoc/langs/l_if
import eoc/langs/l_mon_if
import eoc/passes/remove_complex_operands.{remove_complex_operands}
import gleeunit/should

// (+ 42 (- 10))
//
// rco_atom: (- 10) => #(Var("tmp.1"), %{ "tmp.1" => Neg(Int(10)) })
//
// (let ([tmp.1 (- 10)])
//    (+ 42 tmp.1))
pub fn rco_test() {
  let p =
    l_if.Program(
      l_if.Prim(l_if.Plus(l_if.Int(42), l_if.Prim(l_if.Negate(l_if.Int(10))))),
    )

  let p2 =
    l_mon_if.Program(l_mon_if.Let(
      "tmp.1",
      l_mon_if.Prim(l_mon_if.Negate(l_mon_if.Int(10))),
      l_mon_if.Prim(l_mon_if.Plus(l_mon_if.Int(42), l_mon_if.Var("tmp.1"))),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}

// (let ([a 42])
//    (let ([b a])
//      b))
pub fn rco_noop_test() {
  let p =
    l_if.Program(l_if.Let(
      "a",
      l_if.Int(42),
      l_if.Let("b", l_if.Var("a"), l_if.Var("b")),
    ))

  let p2 =
    l_mon_if.Program(l_mon_if.Let(
      "a",
      l_mon_if.Atomic(l_mon_if.Int(42)),
      l_mon_if.Let(
        "b",
        l_mon_if.Atomic(l_mon_if.Var("a")),
        l_mon_if.Atomic(l_mon_if.Var("b")),
      ),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}

// (+ (- (read)) (read))
//
// (let ([tmp.2 (let ([tmp.1 (read)] (- tmp.1)))])
//  (let ([tmp.3 (read)])
//   (+ tmp.2 tmp.3)
// ))
pub fn rco_order_of_bindings_test() {
  let p =
    l_if.Program(
      l_if.Prim(l_if.Plus(
        l_if.Prim(l_if.Negate(l_if.Prim(l_if.Read))),
        l_if.Prim(l_if.Read),
      )),
    )

  let p2 =
    l_mon_if.Program(l_mon_if.Let(
      "tmp.2",
      l_mon_if.Let(
        "tmp.1",
        l_mon_if.Prim(l_mon_if.Read),
        l_mon_if.Prim(l_mon_if.Negate(l_mon_if.Var("tmp.1"))),
      ),
      l_mon_if.Let(
        "tmp.3",
        l_mon_if.Prim(l_mon_if.Read),
        l_mon_if.Prim(l_mon_if.Plus(
          l_mon_if.Var("tmp.2"),
          l_mon_if.Var("tmp.3"),
        )),
      ),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}

// (if (not (< (read) 10)) 5 42)
//
// (if
//  (let ([tmp.2 (let ([tmp.1 (read)]) (< tmp.1 10))])
//    (not tmp.2))
//  5
//  42
// )
pub fn rco_if_test() {
  let p =
    l_if.Program(l_if.If(
      l_if.Prim(
        l_if.Not(
          l_if.Prim(l_if.Cmp(l_if.Lt, l_if.Prim(l_if.Read), l_if.Int(10))),
        ),
      ),
      l_if.Int(5),
      l_if.Int(42),
    ))

  let p2 =
    l_mon_if.Program(l_mon_if.If(
      l_mon_if.Let(
        "tmp.2",
        l_mon_if.Let(
          "tmp.1",
          l_mon_if.Prim(l_mon_if.Read),
          l_mon_if.Prim(l_mon_if.Cmp(
            l_if.Lt,
            l_mon_if.Var("tmp.1"),
            l_mon_if.Int(10),
          )),
        ),
        l_mon_if.Prim(l_mon_if.Not(l_mon_if.Var("tmp.2"))),
      ),
      l_mon_if.Atomic(l_mon_if.Int(5)),
      l_mon_if.Atomic(l_mon_if.Int(42)),
    ))

  p |> remove_complex_operands |> should.equal(p2)
}
