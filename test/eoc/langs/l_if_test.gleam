import eoc/langs/l_if.{
  And, Bool, BoolValue, Cmp, If, Int, IntValue, Lt, Negate, Not, Plus, Prim,
  Program, interpret,
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
