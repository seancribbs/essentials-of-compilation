import eoc/langs/l_if.{
  And, Bool, BoolValue, Boolean, Cmp, Eq, Gt, Gte, If, Int, IntValue, Integer,
  Let, Lt, Minus, Negate, Not, Or, Plus, Prim, Program, Read, TypeError,
  UnboundVariable, Var, interpret, type_check_program,
}

pub fn l_if_interpreter_test() {
  // (+ 10 (- (+ 12 20)))
  let p =
    Program(Prim(Plus(Int(10), Prim(Negate(Prim(Plus(Int(12), Int(20))))))))

  assert interpret(p) == IntValue(-22)
}

pub fn l_if_interpret_bool_test() {
  // (and (not #f) #t)
  let p = Program(Prim(And(Prim(Not(Bool(False))), Bool(True))))
  assert interpret(p) == BoolValue(True)
}

pub fn l_if_interpret_conditional_test() {
  // (if (< 5 2) 42 3)
  let p = Program(If(Prim(Cmp(Lt, Int(5), Int(2))), Int(42), Int(3)))
  assert interpret(p) == IntValue(3)
}

pub fn l_if_typecheck_program_test() {
  // #t
  // => TypeError(Integer, Boolean, Bool(True))
  assert type_check_program(Program(Bool(True)))
    == Error(TypeError(Integer, Boolean, Bool(True)))
  //
  // (and #f #t)
  // => TypeError(Integer, Boolean, Prim(And(Bool(False), Bool(True))))
  assert type_check_program(Program(Prim(And(Bool(False), Bool(True)))))
    == Error(TypeError(Integer, Boolean, Prim(And(Bool(False), Bool(True)))))
  //
  // (if #t #f #f)
  // => TypeError(Integer, Boolean, If(Bool(True), Bool(False), Bool(False)))
  assert type_check_program(Program(If(Bool(True), Bool(False), Bool(False))))
    == Error(TypeError(
      Integer,
      Boolean,
      If(Bool(True), Bool(False), Bool(False)),
    ))
  //
  // (let [x 42] (< 42 5))
  // => TypeError(Integer, Boolean, Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5))))
  assert type_check_program(
      Program(Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5))))),
    )
    == Error(TypeError(
      Integer,
      Boolean,
      Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5)))),
    ))
}

// Test: internal expression type errors!
pub fn l_if_typecheck_expressions_test() {
  // (if (< 42 #t) 0 1)
  // => TypeError(Integer, Boolean, Bool(True))
  assert type_check_program(
      Program(If(Prim(Cmp(Lt, Int(42), Bool(True))), Int(0), Int(1))),
    )
    == Error(TypeError(Integer, Boolean, Bool(True)))

  // (let (a (+ 5 10)) (= a #f))
  // => TypeError(Integer, Boolean, Prim(Cmp(Eq, Var("a"), Bool(False))))
  assert type_check_program(
      Program(Let(
        "a",
        Prim(Plus(Int(5), Int(10))),
        Prim(Cmp(Eq, Var("a"), Bool(False))),
      )),
    )
    == Error(TypeError(Integer, Boolean, Bool(False)))

  // (if (= 10 2) #f 42)
  // => TypeError(Boolean, Integer, Int(42))
  assert type_check_program(
      Program(If(Prim(Cmp(Eq, Int(10), Int(2))), Bool(False), Int(42))),
    )
    == Error(TypeError(Boolean, Integer, Int(42)))

  // (if (and #f 42) 1 2)
  // => TypeError(Boolean, Integer, Int(42))
  assert type_check_program(
      Program(If(Prim(And(Bool(False), Int(42))), Int(1), Int(2))),
    )
    == Error(TypeError(Boolean, Integer, Int(42)))

  // (if (or (read) #t) 0 1)
  // => TypeError(Boolean, Integer, Prim(Read))
  assert type_check_program(
      Program(If(Prim(Or(Prim(Read), Bool(True))), Int(0), Int(1))),
    )
    == Error(TypeError(Boolean, Integer, Prim(Read)))

  // UnboundVariable
  assert type_check_program(Program(Prim(Plus(Var("a"), Int(2)))))
    == Error(UnboundVariable("a"))
}

// Test: happy path cases
pub fn l_if_typecheck_happy_path_test() {
  // (let [x (read)] (if (>= 42 x) (+ x 5) (- x 10)))
  let assert Ok(_) =
    type_check_program(
      Program(Let(
        "x",
        Prim(Read),
        If(
          Prim(Cmp(Gte, Int(42), Var("x"))),
          Prim(Plus(Var("x"), Int(5))),
          Prim(Minus(Var("x"), Int(10))),
        ),
      )),
    )

  // (let [a (read)] (if (or (> a 5) (not (= a 10))) a 0))
  let assert Ok(_) =
    type_check_program(
      Program(Let(
        "a",
        Prim(Read),
        If(
          Prim(Or(
            Prim(Cmp(Gt, Var("a"), Int(5))),
            Prim(Not(Prim(Cmp(Eq, Var("a"), Int(10))))),
          )),
          Var("a"),
          Int(0),
        ),
      )),
    )
}
