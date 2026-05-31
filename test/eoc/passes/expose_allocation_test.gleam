import eoc/langs/l_alloc_funref as la
import eoc/langs/l_fun as l
import eoc/langs/l_funref as lfr
import eoc/passes/expose_allocation
import eoc/passes/limit_functions
import eoc/passes/parse
import eoc/passes/reveal_functions
import eoc/passes/shrink
import eoc/passes/uniquify

fn parsed(input: String) -> lfr.Program {
  let assert Ok(toks) = parse.tokens(input)
  let assert Ok(untyped) = parse.parse(toks)
  let assert Ok(p) = l.type_check_program(untyped)

  p
  |> shrink.shrink
  |> uniquify.uniquify
  |> reveal_functions.reveal_functions
  |> limit_functions.limit_functions
}

pub fn expose_allocation_test() {
  let p = parsed("(vector-ref (vector-ref (vector (vector 42)) 0) 0)")

  let p2 =
    la.Program([
      la.Definition(
        "main",
        [],
        l.IntegerT,
        la.Prim(la.VectorRef(
          la.HasType(
            la.Prim(la.VectorRef(
              la.Let(
                "vecinit5",
                la.Let(
                  "vecinit1",
                  la.Int(42),
                  la.Let(
                    "_4",
                    la.If(
                      la.Prim(la.Cmp(
                        l.Lt,
                        la.Prim(la.Plus(la.GlobalValue("free_ptr"), la.Int(16))),
                        la.GlobalValue("fromspace_end"),
                      )),
                      la.Prim(la.Void),
                      la.Collect(16),
                    ),
                    la.Let(
                      "alloc2",
                      la.Allocate(1, l.VectorT([l.IntegerT])),
                      la.Let(
                        "_3",
                        la.Prim(la.VectorSet(
                          la.HasType(la.Var("alloc2"), l.VectorT([l.IntegerT])),
                          la.Int(0),
                          la.Var("vecinit1"),
                        )),
                        la.HasType(la.Var("alloc2"), l.VectorT([l.IntegerT])),
                      ),
                    ),
                  ),
                ),
                la.Let(
                  "_8",
                  la.If(
                    la.Prim(la.Cmp(
                      l.Lt,
                      la.Prim(la.Plus(la.GlobalValue("free_ptr"), la.Int(16))),
                      la.GlobalValue("fromspace_end"),
                    )),
                    la.Prim(la.Void),
                    la.Collect(16),
                  ),
                  la.Let(
                    "alloc6",
                    la.Allocate(1, l.VectorT([l.VectorT([l.IntegerT])])),
                    la.Let(
                      "_7",
                      la.Prim(la.VectorSet(
                        la.HasType(
                          la.Var("alloc6"),
                          l.VectorT([l.VectorT([l.IntegerT])]),
                        ),
                        la.Int(0),
                        la.Var("vecinit5"),
                      )),
                      la.HasType(
                        la.Var("alloc6"),
                        l.VectorT([l.VectorT([l.IntegerT])]),
                      ),
                    ),
                  ),
                ),
              ),
              la.Int(0),
            )),
            l.VectorT([l.IntegerT]),
          ),
          la.Int(0),
        )),
      ),
    ])

  assert expose_allocation.expose_allocation(p) == p2
}
