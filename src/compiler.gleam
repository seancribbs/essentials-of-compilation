import gleam/io
import langs/l_int.{Int, Plus, Prim, Program, Read, interpret}

pub fn main() {
  let p = Program(Prim(Plus(Int(8), Prim(Read))))
  io.debug(interpret(p))
}
// patch_instructions (fix outstanding problems)
//    x86int -> x86int
// prelude_and_conclusion
//    x86int -> x86int
