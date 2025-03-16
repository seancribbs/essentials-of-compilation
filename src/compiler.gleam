import gleam/io
import langs/l_int.{Int, Plus, Prim, Program, Read, interpret}

pub fn main() {
  let p = Program(Prim(Plus(Int(8), Prim(Read))))
  io.debug(interpret(p))
}
// select_instructions (convert Lvar into sequences instructions)
//    Cvar -> x86var
// assign_homes (replaces variables with registers or stack locations)
//    x86var -> x86var
// patch_instructions (fix outstanding problems)
//    x86var -> x86int
// prelude_and_conclusion
//    x86int -> x86int
