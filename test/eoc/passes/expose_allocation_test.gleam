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

  let p2 =
    la.Program(
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
    )

  p |> expose_allocation.expose_allocation |> should.equal(p2)
}
