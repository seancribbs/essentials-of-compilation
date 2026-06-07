import eoc/langs/l_alloc_funref as l
import eoc/langs/l_fun.{IntegerT, type_check_program}
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uncover_get.{collect_set_bang, uncover_get}
import eoc/passes/uniquify
import gleam/set

fn parsed(input: String) -> l.Program {
  let assert Ok(tokens) = parse.tokens(input)
  let assert Ok(untyped) = parse.parse(tokens)
  let assert Ok(ast) = type_check_program(untyped)
  ast
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
  |> limit_functions.limit_functions
  |> expose_allocation.expose_allocation
}

pub fn uncover_get_test() {
  let p =
    parsed(
      "
  (let ([x 2])
    (let ([y 0])
      (+ y (+ x (begin (set! x 40) x)))))
  ",
    )

  let p2 =
    l.Program([
      l.Definition(
        "main",
        [],
        IntegerT,
        l.Let(
          "x.1",
          l.Int(2),
          l.Let(
            "y.2",
            l.Int(0),
            l.Prim(l.Plus(
              l.Var("y.2"),
              l.Prim(l.Plus(
                l.GetBang("x.1"),
                l.Begin([l.SetBang("x.1", l.Int(40))], l.GetBang("x.1")),
              )),
            )),
          ),
        ),
      ),
    ])

  assert uncover_get(p) == p2
}

pub fn collect_set_bang_test() {
  let assert l.Program([p]) =
    parsed(
      "
  (let ([x 2])
    (let ([y 0])
      (+ y (+ x (begin (set! x 40) x)))))
  ",
    )

  assert collect_set_bang(p.body) == set.from_list(["x.1"])

  let assert l.Program([p2]) =
    parsed(
      "(let ([sum 0])
      (let ([i 5])
        (begin
          (while (> i 0)
            (begin
              (set! sum (+ sum i))
              (set! i (- i 1))))
          sum)))",
    )

  assert collect_set_bang(p2.body) == set.from_list(["sum.1", "i.2"])
}
