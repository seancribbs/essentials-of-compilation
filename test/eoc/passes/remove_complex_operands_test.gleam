// // import gleeunit
import eoc/langs/l_alloc_funref as l
import eoc/langs/l_fun.{BooleanT, Eq, IntegerT, Lt, VectorT, type_check_program}
import eoc/langs/l_mon_funref as l_mon
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/remove_complex_operands.{remove_complex_operands}
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uncover_get
import eoc/passes/uniquify
import gleam/list

// (+ 42 (- 10))
//
// rco_atom: (- 10) => #(Var("tmp.1"), %{ "tmp.1" => Neg(Int(10)) })
//
// (let ([tmp.1 (- 10)])
//    (+ 42 tmp.1))
pub fn rco_test() {
  let p =
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.Prim(l.Plus(l.Int(42), l.Prim(l.Negate(l.Int(10))))),
      ),
    ])

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.Let(
          "tmp.1",
          l_mon.Prim(l_mon.Negate(l_mon.Int(10))),
          l_mon.Prim(l_mon.Plus(l_mon.Int(42), l_mon.Var("tmp.1"))),
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
}

// (let ([a 42])
//    (let ([b a])
//      b))
pub fn rco_noop_test() {
  let p =
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.Let("a", l.Int(42), l.Let("b", l.Var("a"), l.Var("b"))),
      ),
    ])

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.Let(
          "a",
          l_mon.Atomic(l_mon.Int(42)),
          l_mon.Let(
            "b",
            l_mon.Atomic(l_mon.Var("a")),
            l_mon.Atomic(l_mon.Var("b")),
          ),
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
}

// (+ (- (read)) (read))
//
// (let ([tmp.2 (let ([tmp.1 (read)] (- tmp.1)))])
//  (let ([tmp.3 (read)])
//   (+ tmp.2 tmp.3)
// ))
pub fn rco_order_of_bindings_test() {
  let p =
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.Prim(l.Plus(l.Prim(l.Negate(l.Prim(l.Read))), l.Prim(l.Read))),
      ),
    ])

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.Let(
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
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
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
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.If(
          l.Prim(l.Not(l.Prim(l.Cmp(Lt, l.Prim(l.Read), l.Int(10))))),
          l.Int(5),
          l.Int(42),
        ),
      ),
    ])

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.If(
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
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
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
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.Let(
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
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
}

pub fn rco_tuple_test() {
  // GlobalValue is complex
  let p =
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.If(
          l.Prim(l.Cmp(
            Lt,
            l.Prim(l.Plus(l.GlobalValue("free_ptr"), l.Int(16))),
            l.GlobalValue("fromspace_end"),
          )),
          l.Int(42),
          l.Int(43),
        ),
      ),
    ])

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.If(
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
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
}

pub fn rco_transform_vector_ref_condition_test() {
  let p =
    "
(let ([v1 (vector 42 #t)])
  (if (vector-ref v1 1)
    5
    (vector-ref v1 0)))
"
    |> parsed()

  let p2 =
    l_mon.Program([
      l_mon.Definition(
        "main",
        [],
        IntegerT,
        l_mon.Let(
          "v1.1",
          l_mon.Let(
            "vecinit1",
            l_mon.Atomic(l_mon.Int(42)),
            l_mon.Let(
              "vecinit2",
              l_mon.Atomic(l_mon.Bool(True)),
              l_mon.Let(
                "_6",
                l_mon.If(
                  l_mon.Let(
                    "tmp.2",
                    l_mon.Let(
                      "tmp.1",
                      l_mon.GlobalValue("free_ptr"),
                      l_mon.Prim(l_mon.Plus(l_mon.Var("tmp.1"), l_mon.Int(24))),
                    ),
                    l_mon.Let(
                      "tmp.3",
                      l_mon.GlobalValue("fromspace_end"),
                      l_mon.Prim(l_mon.Cmp(
                        Lt,
                        l_mon.Var("tmp.2"),
                        l_mon.Var("tmp.3"),
                      )),
                    ),
                  ),
                  l_mon.Atomic(l_mon.Void),
                  l_mon.Collect(24),
                ),
                l_mon.Let(
                  "alloc3",
                  l_mon.Allocate(2, VectorT([IntegerT, BooleanT])),
                  l_mon.Let(
                    "_5",
                    l_mon.Prim(l_mon.VectorSet(
                      l_mon.HasType(
                        l_mon.Var("alloc3"),
                        VectorT([IntegerT, BooleanT]),
                      ),
                      l_mon.Int(0),
                      l_mon.Var("vecinit1"),
                    )),
                    l_mon.Let(
                      "_4",
                      l_mon.Prim(l_mon.VectorSet(
                        l_mon.HasType(
                          l_mon.Var("alloc3"),
                          VectorT([IntegerT, BooleanT]),
                        ),
                        l_mon.Int(1),
                        l_mon.Var("vecinit2"),
                      )),
                      l_mon.Atomic(l_mon.Var("alloc3")),
                    ),
                  ),
                ),
              ),
            ),
          ),
          l_mon.If(
            l_mon.Let(
              "tmp.4",
              l_mon.Prim(l_mon.VectorRef(
                l_mon.HasType(l_mon.Var("v1.1"), VectorT([IntegerT, BooleanT])),
                l_mon.Int(1),
              )),
              l_mon.Prim(l_mon.Cmp(Eq, l_mon.Var("tmp.4"), l_mon.Bool(True))),
            ),
            l_mon.Atomic(l_mon.Int(5)),
            l_mon.Prim(l_mon.VectorRef(
              l_mon.HasType(l_mon.Var("v1.1"), VectorT([IntegerT, BooleanT])),
              l_mon.Int(0),
            )),
          ),
        ),
      ),
    ])

  assert remove_complex_operands(p) == p2
}

pub fn rco_apply_funref_test() {
  let p =
    parsed(
      "
    (define (map [f : (Integer -> Integer)] [v : (Vector Integer Integer)]) : (Vector Integer Integer)
      (vector (f (vector-ref v 0)) (f (vector-ref v 1))))

    (define (inc [x : Integer]) : Integer
      (+ x 1))

    (vector-ref (map inc (vector 0 41)) 1)
  ",
    )
    |> remove_complex_operands

  // (let ([tmp.1 map])
  //   (let ([tmp.2 inc])
  //     (let)))
  let assert Ok(main) = list.find(p.defs, fn(d) { d.name == "main" })
  let assert l_mon.Let("tmp.1", l_mon.FunRef("map", 2), inner) = main.body
  let assert l_mon.Let("tmp.2", l_mon.FunRef("inc", 1), _) = inner

  // inc has no complex expressions
  let assert Ok(inc) = list.find(p.defs, fn(d) { d.name == "inc" })
  assert l_mon.Prim(l_mon.Plus(l_mon.Var("x.3"), l_mon.Int(1))) == inc.body

  // map should turn vector-ref result into lets
  let assert Ok(map) = list.find(p.defs, fn(d) { d.name == "map" })
  let assert l_mon.Let(
    "vecinit1",
    l_mon.Let(
      "tmp.1",
      l_mon.Prim(l_mon.VectorRef(
        l_mon.HasType(l_mon.Var("v.2"), VectorT([IntegerT, IntegerT])),
        l_mon.Int(0),
      )),
      l_mon.Apply(l_mon.Var("f.1"), [l_mon.Var("tmp.1")]),
    ),
    _,
  ) = map.body
}

fn parsed(input: String) -> l.Program {
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
}
