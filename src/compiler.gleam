import gleam/io
import l_int.{Int, Plus, Prim, Program, Read, interpret}

pub fn main() {
  let p = Program(Prim(Plus(Int(8), Prim(Read))))
  io.debug(interpret(p))
}
