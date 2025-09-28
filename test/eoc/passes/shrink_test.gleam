import eoc/langs/l_tup.{
  And, Bool, BoolValue, BooleanT, Cmp, Eq, If, Int, IntValue, IntegerT, Let, Lt,
  Negate, Not, Or, Plus, Prim, Program, Read, TypeError, UnboundVariable, Var,
  interpret, type_check_program,
}
import eoc/passes/shrink.{shrink}

import gleeunit/should

pub fn shrink_short_circuit_test() {
  // (if (and #t #f) 0 1)
  // => (if (if #t #f #f) 0 1)
  Program(If(Prim(And(Bool(True), Bool(False))), Int(0), Int(1)))
  |> shrink
  |> should.equal(
    Program(If(If(Bool(True), Bool(False), Bool(False)), Int(0), Int(1))),
  )

  // (if (or #t #f) 0 1)
  // => (if (if #t #t #f) 0 1)
  Program(If(Prim(Or(Bool(True), Bool(False))), Int(0), Int(1)))
  |> shrink
  |> should.equal(
    Program(If(If(Bool(True), Bool(True), Bool(False)), Int(0), Int(1))),
  )
}

pub fn shrink_preserves_semantics_interpret_test() {
  // (+ 10 (- (+ 12 20)))
  let p =
    Program(Prim(Plus(Int(10), Prim(Negate(Prim(Plus(Int(12), Int(20))))))))

  p |> shrink |> interpret |> should.equal(IntValue(-22))

  // (and (not #f) #t)
  let p = Program(Prim(And(Prim(Not(Bool(False))), Bool(True))))
  p |> shrink |> interpret |> should.equal(BoolValue(True))

  // (if (< 5 2) 42 3)
  let p = Program(If(Prim(Cmp(Lt, Int(5), Int(2))), Int(42), Int(3)))
  p |> shrink |> interpret |> should.equal(IntValue(3))
}

pub fn shrink_preserves_semantics_type_check_test() {
  // #t
  // => TypeError(Integer, Boolean, Bool(True))
  Program(Bool(True))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(IntegerT, BooleanT, Bool(True))))
  //
  // (and #f #t)
  // => TypeError(Integer, Boolean, Prim(And(Bool(False), Bool(True))))
  // !!!! THIS ONE IS TRANSFORMED BY THE PASS !!!!
  Program(Prim(And(Bool(False), Bool(True))))
  |> shrink
  |> type_check_program
  |> should.equal(
    Error(TypeError(
      IntegerT,
      BooleanT,
      If(Bool(False), Bool(True), Bool(False)),
    )),
  )
  //
  // (if #t #f #f)
  // => TypeError(Integer, Boolean, If(Bool(True), Bool(False), Bool(False)))
  Program(If(Bool(True), Bool(False), Bool(False)))
  |> shrink
  |> type_check_program
  |> should.equal(
    Error(TypeError(
      IntegerT,
      BooleanT,
      If(Bool(True), Bool(False), Bool(False)),
    )),
  )
  //
  // (let [x 42] (< 42 5))
  // => TypeError(Integer, Boolean, Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5))))
  Program(Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5)))))
  |> shrink
  |> type_check_program
  |> should.equal(
    Error(TypeError(
      IntegerT,
      BooleanT,
      Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5)))),
    )),
  )
}

pub fn shrink_preserves_semantics_typecheck_expression_test() {
  // (if (< 42 #t) 0 1)
  // => TypeError(Integer, Boolean, Bool(True))
  Program(If(Prim(Cmp(Lt, Int(42), Bool(True))), Int(0), Int(1)))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(IntegerT, BooleanT, Bool(True))))

  // (let (a (+ 5 10)) (= a #f))
  // => TypeError(Integer, Boolean, Prim(Cmp(Eq, Var("a"), Bool(False))))
  Program(Let(
    "a",
    Prim(Plus(Int(5), Int(10))),
    Prim(Cmp(Eq, Var("a"), Bool(False))),
  ))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(IntegerT, BooleanT, Bool(False))))

  // (if (= 10 2) #f 42)
  // => TypeError(Boolean, Integer, Int(42))
  Program(If(Prim(Cmp(Eq, Int(10), Int(2))), Bool(False), Int(42)))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(BooleanT, IntegerT, Int(42))))

  // (if (and #f 42) 1 2) ... (if (if #f 42 #f) 1 2)
  // => TypeError(Boolean, Integer, Int(42))
  // !!!! THIS ONE IS TRANSFORMED BY THE PASS !!!!
  Program(If(Prim(And(Bool(False), Int(42))), Int(1), Int(2)))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(IntegerT, BooleanT, Bool(False))))

  // (if (or (read) #t) 0 1)
  // => TypeError(Boolean, Integer, Prim(Read))
  Program(If(Prim(Or(Prim(Read), Bool(True))), Int(0), Int(1)))
  |> shrink
  |> type_check_program
  |> should.equal(Error(TypeError(BooleanT, IntegerT, Prim(Read))))

  // UnboundVariable
  Program(Prim(Plus(Var("a"), Int(2))))
  |> shrink
  |> type_check_program
  |> should.equal(Error(UnboundVariable("a")))
}
