import eoc/langs/l_fun as l
import eoc/langs/l_funref as lfr
import eoc/passes/parse
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uniquify
import gleam/list

fn program(input: String) -> l.Program {
  let assert Ok(toks) = parse.tokens(input)
  let assert Ok(p) = parse.parse(toks)
  let assert Ok(p) = l.type_check_program(p)
  p
  |> shrink.shrink
  |> uniquify.uniquify
}

pub fn reveal_functions_test() {
  let p =
    program(
      "(define (map [f : (Integer -> Integer)] [v : (Vector Integer Integer)]) : (Vector Integer Integer)
      (vector (f (vector-ref v 0)) (f (vector-ref v 1))))

    (define (inc [x : Integer]) : Integer
      (+ x 1))

      (vector-ref (map inc (vector 0 41)) 1)",
    )

  let p2 = reveal_functions.reveal_functions(p)
  let assert Ok(main) =
    list.find_map(p2.defs, fn(d) {
      case d.name {
        "main" -> Ok(d.body)
        _ -> Error(Nil)
      }
    })

  assert main
    == lfr.Prim(lfr.VectorRef(
      lfr.HasType(
        lfr.Apply(
          lfr.HasType(
            lfr.FunRef("map", 2),
            l.FunT(
              [
                l.FunT([l.IntegerT], l.IntegerT),
                l.VectorT([l.IntegerT, l.IntegerT]),
              ],
              l.VectorT([l.IntegerT, l.IntegerT]),
            ),
          ),
          [
            lfr.FunRef("inc", 1),
            lfr.HasType(
              lfr.Prim(lfr.Vector([lfr.Int(0), lfr.Int(41)])),
              l.VectorT([l.IntegerT, l.IntegerT]),
            ),
          ],
        ),
        l.VectorT([l.IntegerT, l.IntegerT]),
      ),
      lfr.Int(1),
    ))
}
