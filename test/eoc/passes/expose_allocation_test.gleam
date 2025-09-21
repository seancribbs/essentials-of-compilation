import eoc/langs/l_alloc as la
import eoc/langs/l_tup as l
import eoc/passes/expose_allocation
import eoc/passes/parse
import gleeunit/should

fn parsed(input: String) -> l.Program {
  input
  |> parse.tokens()
  |> should.be_ok()
  |> parse.parse()
  |> should.be_ok()
  |> l.type_check_program()
  |> should.be_ok()
}

pub fn expose_allocation_test() {
  let p = parsed("(vector-ref (vector-ref (vector (vector 42)) 0) 0)")

  echo expose_allocation.expose_allocation(p)

  should.fail
}
