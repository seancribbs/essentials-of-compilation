import eoc/langs/l_fun.{
  Bool, Cmp, Definition, Gte, If, Int, IntegerT, Let, Lt, Minus, Or, Plus, Prim,
  ProgramDefs, Read, Var,
}
import eoc/passes/uniquify.{uniquify}

// (let ([x 32]) (+ let ([x 10]) x) x)
// (let ([x.1 32]) (+ let ([x.2 10]) x.2) x.1)
pub fn uniquify_test() {
  let p =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let("x", Int(32), Prim(Plus(Let("x", Int(10), Var("x")), Var("x")))),
      ),
    ])

  let p1 =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let(
          "x.1",
          Int(32),
          Prim(Plus(Let("x.2", Int(10), Var("x.2")), Var("x.1"))),
        ),
      ),
    ])

  assert uniquify(p) == p1
}

// (let ([x (let ([x 4]) (+ x 1))]) (+ x 2))
// (let ([x.2 (let ([x.1 4]) (+ x.1 1))]) (+ x.2 2))
pub fn uniquify_inner_let_test() {
  let p =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let(
          "x",
          Let("x", Int(4), Prim(Plus(Var("x"), Int(1)))),
          Prim(Plus(Var("x"), Int(2))),
        ),
      ),
    ])

  let p1 =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let(
          "x.2",
          Let("x.1", Int(4), Prim(Plus(Var("x.1"), Int(1)))),
          Prim(Plus(Var("x.2"), Int(2))),
        ),
      ),
    ])

  assert uniquify(p) == p1
}

// (if (< 5 2) (let ([x 42]) (+ x 10)) (let ([y 30]) (- y 5)))
// (if (< 5 2) (let ([x.1 42]) (+ x.1 10)) (let ([y.2 30]) (- y.2 5)))
pub fn uniquify_if_test() {
  let p =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        If(
          Prim(Cmp(Lt, Int(5), Int(2))),
          Let("x", Int(42), Prim(Plus(Var("x"), Int(10)))),
          Let("y", Int(30), Prim(Minus(Var("y"), Int(5)))),
        ),
      ),
    ])

  let p2 =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        If(
          Prim(Cmp(Lt, Int(5), Int(2))),
          Let("x.1", Int(42), Prim(Plus(Var("x.1"), Int(10)))),
          Let("y.2", Int(30), Prim(Minus(Var("y.2"), Int(5)))),
        ),
      ),
    ])

  assert uniquify(p) == p2
}

// (let ([x (if (>= (read) 10) #f #t)]) (if (or x #t) 5 10))
// (let ([x.1 (if (>= (read) 10) #f #t)]) (if (or x.1 #t) 5 10))
pub fn uniquify_boolean_ops_test() {
  let p =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let(
          "x",
          If(Prim(Cmp(Gte, Prim(Read), Int(10))), Bool(False), Bool(True)),
          If(Prim(Or(Var("x"), Bool(True))), Int(5), Int(10)),
        ),
      ),
    ])

  let p2 =
    ProgramDefs([
      Definition(
        "main",
        [],
        IntegerT,
        Let(
          "x.1",
          If(Prim(Cmp(Gte, Prim(Read), Int(10))), Bool(False), Bool(True)),
          If(Prim(Or(Var("x.1"), Bool(True))), Int(5), Int(10)),
        ),
      ),
    ])

  assert uniquify(p) == p2
}

pub fn uniquify_preserves_function_names_test() {
  let p =
    ProgramDefs([
      Definition(
        name: "f",
        arguments: [#("a", IntegerT)],
        return: IntegerT,
        body: Prim(Plus(Var("a"), Int(1))),
      ),
      Definition(
        name: "main",
        arguments: [],
        return: IntegerT,
        body: l_fun.Apply(Var("f"), [Int(41)]),
      ),
    ])

  let p2 =
    ProgramDefs([
      Definition(
        name: "f",
        arguments: [#("a.1", IntegerT)],
        return: IntegerT,
        body: Prim(Plus(Var("a.1"), Int(1))),
      ),
      Definition(
        name: "main",
        arguments: [],
        return: IntegerT,
        body: l_fun.Apply(Var("f"), [Int(41)]),
      ),
    ])

  assert uniquify(p) == p2
}
