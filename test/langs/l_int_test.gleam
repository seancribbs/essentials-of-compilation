import gleeunit/should
import langs/l_int.{Int, Negate, Plus, Prim, Program, Read, partial}

pub fn partial_eval_test() {
  let p = Program(Prim(Plus(Int(10), Prim(Negate(Prim(Plus(Int(5), Int(3))))))))
  p |> partial() |> should.equal(Program(Int(2)))

  // (+ (read) (- (+ 5 3)))
  let p2 =
    Program(Prim(Plus(Prim(Read), Prim(Negate(Prim(Plus(Int(5), Int(3))))))))
  // (+ (read) -8)
  p2 |> partial() |> should.equal(Program(Prim(Plus(Prim(Read), Int(-8)))))
}
