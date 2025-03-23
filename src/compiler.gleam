import gleam/io
import langs/l_int.{Int, Plus, Prim, Program, Read, interpret}

pub fn main() {
  let p = Program(Prim(Plus(Int(8), Prim(Read))))
  io.debug(interpret(p))
}
// prelude_and_conclusion
//    x86int -> x86int
