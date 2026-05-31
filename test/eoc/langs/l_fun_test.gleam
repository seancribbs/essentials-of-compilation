import eoc/langs/l_fun
import eoc/passes/parse

pub fn function_application_carries_type_test() {
  let assert Ok(toks) =
    parse.tokens(
      "
    (define (foo [a : Integer] [b : Integer]) : Integer
      (+ a b))

    (foo 1 41)
    ",
    )
  let assert Ok(program) = parse.parse(toks)

  let assert Ok(l_fun.ProgramDefsExp(defs: _, body:)) =
    l_fun.type_check_program(program)

  assert l_fun.Apply(
      l_fun.HasType(
        l_fun.Var("foo"),
        l_fun.FunT([l_fun.IntegerT, l_fun.IntegerT], l_fun.IntegerT),
      ),
      [l_fun.Int(1), l_fun.Int(41)],
    )
    == body
}
