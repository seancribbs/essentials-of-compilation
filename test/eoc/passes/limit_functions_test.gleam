import eoc/langs/l_fun as l
import eoc/langs/l_funref as lfr
import eoc/passes/limit_functions.{limit_functions}
import eoc/passes/parse
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uniquify
import gleam/list

pub fn limit_function_arguments_to_6_test() {
  let p =
    program(
      "
    (define
      (foo
        [a : Integer]
        [b : Integer]
        [c : Integer]
        [d : Integer]
        [e : Integer]
        [f : Integer]
        [g : Integer]
        [h : Integer])
      :
      Integer


      (+ (+ (+ (+ (+ (+ (+ a b) c) d) e) f) g) h))
    (foo 1 2 3 4 5 6 7 8)
    ",
    )
    |> limit_functions

  let assert Ok(foo) = list.find(p.defs, fn(def) { def.name == "foo" })
  assert list.length(foo.arguments) == 6
  assert Ok(#("tup", l.VectorT([l.IntegerT, l.IntegerT, l.IntegerT])))
    == list.last(foo.arguments)
  let assert lfr.Prim(lfr.Plus(
    a: lfr.Prim(lfr.Plus(
      a: lfr.Prim(lfr.Plus(
        a: _,
        b: lfr.Prim(lfr.VectorRef(v: lfr.Var("tup"), index: lfr.Int(0))),
      )),
      b: lfr.Prim(lfr.VectorRef(v: lfr.Var("tup"), index: lfr.Int(1))),
    )),
    b: lfr.Prim(lfr.VectorRef(v: lfr.Var("tup"), index: lfr.Int(2))),
  )) = foo.body

  let assert Ok(main) = list.find(p.defs, fn(def) { def.name == "main" })
  assert main.body
    == lfr.Apply(lfr.FunRef("foo", 6), [
      lfr.Int(1),
      lfr.Int(2),
      lfr.Int(3),
      lfr.Int(4),
      lfr.Int(5),
      lfr.HasType(
        lfr.Prim(lfr.Vector([lfr.Int(6), lfr.Int(7), lfr.Int(8)])),
        l.VectorT([l.IntegerT, l.IntegerT, l.IntegerT]),
      ),
    ])
}

fn program(input: String) -> lfr.Program {
  let assert Ok(toks) = parse.tokens(input)
  let assert Ok(p) = parse.parse(toks)
  let assert Ok(p) = l.type_check_program(p)
  p
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
}
