import eoc/langs/l_if.{
  And, Bool, BoolValue, Boolean, Cmp, If, Int, IntValue, Integer, Let, Lt,
  Negate, Not, Plus, Prim, Program, TypeError, interpret, type_check_program,
}
import gleeunit/should

pub fn l_if_interpreter_test() {
  // (+ 10 (- (+ 12 20)))
  let p =
    Program(Prim(Plus(Int(10), Prim(Negate(Prim(Plus(Int(12), Int(20))))))))

  p |> interpret |> should.equal(IntValue(-22))
}

pub fn l_if_interpret_bool_test() {
  // (and (not #f) #t)
  let p = Program(Prim(And(Prim(Not(Bool(False))), Bool(True))))
  p |> interpret |> should.equal(BoolValue(True))
}

pub fn l_if_interpret_conditional_test() {
  // (if (< 5 2) 42 3)
  let p = Program(If(Prim(Cmp(Lt, Int(5), Int(2))), Int(42), Int(3)))
  p |> interpret |> should.equal(IntValue(3))
}

pub fn l_if_typecheck_program_test() {
  // #t
  // => TypeError(Integer, Boolean, Bool(True))
  Program(Bool(True))
  |> type_check_program
  |> should.equal(Error(TypeError(Integer, Boolean, Bool(True))))
  //
  // (and #f #t)
  // => TypeError(Integer, Boolean, Prim(And(Bool(False), Bool(True))))
  Program(Prim(And(Bool(False), Bool(True))))
  |> type_check_program
  |> should.equal(
    Error(TypeError(Integer, Boolean, Prim(And(Bool(False), Bool(True))))),
  )
  //
  // (if #t #f #f)
  // => TypeError(Integer, Boolean, If(Bool(True), Bool(False), Bool(False)))
  Program(If(Bool(True), Bool(False), Bool(False)))
  |> type_check_program
  |> should.equal(
    Error(TypeError(Integer, Boolean, If(Bool(True), Bool(False), Bool(False)))),
  )
  //
  // (let [x 42] (< 42 5))
  // => TypeError(Integer, Boolean, Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5))))
  Program(Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5)))))
  |> type_check_program
  |> should.equal(
    Error(TypeError(
      Integer,
      Boolean,
      Let("x", Int(42), Prim(Cmp(Lt, Int(42), Int(5)))),
    )),
  )
}
// Test: internal expression type errors!
// Test: happy path cases
