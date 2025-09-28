// import gleeunit
import eoc/langs/l_alloc as l
import eoc/langs/l_mon_alloc as l_mon
import eoc/langs/l_tup.{Lt, type_check_program}
import eoc/passes/expose_allocation
import eoc/passes/parse.{parse, tokens}
import eoc/passes/remove_complex_operands.{remove_complex_operands}
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uniquify
import gleeunit/should

// (+ 42 (- 10))
//
// rco_atom: (- 10) => #(Var("tmp.1"), %{ "tmp.1" => Neg(Int(10)) })
//
// (let ([tmp.1 (- 10)])
//    (+ 42 tmp.1))
pub fn rco_test() {
  let p = l.Program(l.Prim(l.Plus(l.Int(42), l.Prim(l.Negate(l.Int(10))))))

  let p2 =
    l_mon.Program(l_mon.Let(
      "tmp.1",
      l_mon.Prim(l_mon.Negate(l_mon.Int(10))),
      l_mon.Prim(l_mon.Plus(l_mon.Int(42), l_mon.Var("tmp.1"))),
    ))

  p |> remove_complex_operands() |> should.equal(p2)
}

// (let ([a 42])
//    (let ([b a])
//      b))
pub fn rco_noop_test() {
  let p = l.Program(l.Let("a", l.Int(42), l.Let("b", l.Var("a"), l.Var("b"))))

  let p2 =
    l_mon.Program(l_mon.Let(
      "a",
      l_mon.Atomic(l_mon.Int(42)),
      l_mon.Let("b", l_mon.Atomic(l_mon.Var("a")), l_mon.Atomic(l_mon.Var("b"))),
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
    l.Program(l.Prim(l.Plus(l.Prim(l.Negate(l.Prim(l.Read))), l.Prim(l.Read))))

  let p2 =
    l_mon.Program(l_mon.Let(
      "tmp.2",
      l_mon.Let(
        "tmp.1",
        l_mon.Prim(l_mon.Read),
        l_mon.Prim(l_mon.Negate(l_mon.Var("tmp.1"))),
      ),
      l_mon.Let(
        "tmp.3",
        l_mon.Prim(l_mon.Read),
        l_mon.Prim(l_mon.Plus(l_mon.Var("tmp.2"), l_mon.Var("tmp.3"))),
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
    l.Program(l.If(
      l.Prim(l.Not(l.Prim(l.Cmp(Lt, l.Prim(l.Read), l.Int(10))))),
      l.Int(5),
      l.Int(42),
    ))

  let p2 =
    l_mon.Program(l_mon.If(
      l_mon.Let(
        "tmp.2",
        l_mon.Let(
          "tmp.1",
          l_mon.Prim(l_mon.Read),
          l_mon.Prim(l_mon.Cmp(Lt, l_mon.Var("tmp.1"), l_mon.Int(10))),
        ),
        l_mon.Prim(l_mon.Not(l_mon.Var("tmp.2"))),
      ),
      l_mon.Atomic(l_mon.Int(5)),
      l_mon.Atomic(l_mon.Int(42)),
    ))

  p |> remove_complex_operands |> should.equal(p2)
}

pub fn rco_loops_test() {
  let p =
    parsed(
      "
  (let ([x2 10])
    (let ([y3 0])
      (+ (+ (begin
              (set! y3 (read))
              x2)
            (begin
              (set! x2 (read))
              y3))
          x2)))
  ",
    )
  // becomes
  // (let ([x2 10])
  //  (let ([y3 0])
  //    (let ([tmp.3
  //           (let ([tmp.1 (begin
  //                           (set! y3 (read))
  //                           (get! x2))])
  //              (let ([tmp.2 (begin
  //                             (set! x2 (read))
  //                             (get! y3))])
  //                (+ tmp.1 tmp.2)))])
  //   (let ([tmp.4 (get! x2)])
  //    (+ tmp.3 tmp.4))
  // )
  //  )
  // )

  let p2 =
    l_mon.Program(l_mon.Let(
      "x2.1",
      l_mon.Atomic(l_mon.Int(10)),
      l_mon.Let(
        "y3.2",
        l_mon.Atomic(l_mon.Int(0)),
        l_mon.Let(
          "tmp.3",
          l_mon.Let(
            "tmp.1",
            l_mon.Begin(
              [l_mon.SetBang("y3.2", l_mon.Prim(l_mon.Read))],
              l_mon.GetBang("x2.1"),
            ),
            l_mon.Let(
              "tmp.2",
              l_mon.Begin(
                [l_mon.SetBang("x2.1", l_mon.Prim(l_mon.Read))],
                l_mon.GetBang("y3.2"),
              ),
              l_mon.Prim(l_mon.Plus(l_mon.Var("tmp.1"), l_mon.Var("tmp.2"))),
            ),
          ),
          l_mon.Let(
            "tmp.4",
            l_mon.GetBang("x2.1"),
            l_mon.Prim(l_mon.Plus(l_mon.Var("tmp.3"), l_mon.Var("tmp.4"))),
          ),
        ),
      ),
    ))

  p |> remove_complex_operands |> should.equal(p2)
}

pub fn rco_tuple_test() {
  // GlobalValue is complex
  let p =
    l.Program(l.If(
      l.Prim(l.Cmp(
        Lt,
        l.Prim(l.Plus(l.GlobalValue("free_ptr"), l.Int(16))),
        l.GlobalValue("fromspace_end"),
      )),
      l.Int(42),
      l.Int(43),
    ))

  let p2 =
    l_mon.Program(l_mon.If(
      l_mon.Let(
        "tmp.2",
        l_mon.Let(
          "tmp.1",
          l_mon.GlobalValue("free_ptr"),
          l_mon.Prim(l_mon.Plus(l_mon.Var("tmp.1"), l_mon.Int(16))),
        ),
        l_mon.Let(
          "tmp.3",
          l_mon.GlobalValue("fromspace_end"),
          l_mon.Prim(l_mon.Cmp(Lt, l_mon.Var("tmp.2"), l_mon.Var("tmp.3"))),
        ),
      ),
      l_mon.Atomic(l_mon.Int(42)),
      l_mon.Atomic(l_mon.Int(43)),
    ))

  p |> remove_complex_operands |> should.equal(p2)
}

fn parsed(input: String) -> l.Program {
  input
  |> tokens
  |> should.be_ok
  |> parse
  |> should.be_ok
  |> type_check_program
  |> should.be_ok
  |> shrink.shrink
  |> uniquify.uniquify
  |> expose_allocation.expose_allocation
  |> uncover_get.uncover_get
}
