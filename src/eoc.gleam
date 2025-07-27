import eoc/langs/l_while as l
import eoc/passes/allocate_registers
import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/generate_prelude_and_conclusion
import eoc/passes/parse
import eoc/passes/patch_instructions
import eoc/passes/remove_complex_operands
import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_live
import eoc/passes/uniquify
import gleam/io

pub fn main() {
  // let p =
  //   l.Program(l.Let(
  //     "y",
  //     l.Let(
  //       "x",
  //       l.Int(20),
  //       l.Prim(l.Plus(l.Var("x"), l.Let("x", l.Int(22), l.Var("x")))),
  //     ),
  //     l.Var("y"),
  //   ))

  // let p =
  //   l.Program(l.If(
  //     l.Prim(l.Cmp(l.Eq, l.Prim(l.Read), l.Int(1))),
  //     l.Int(42),
  //     l.Int(0),
  //   ))

  // (let ([y (if #t
  //            (read)
  //            (if (eq? (read) 0)
  //                777
  //                (let ([x (read)]) (+ 1 x))))])
  //  (+ y 2))
  //
  // let p =
  //   l.Program(l.Let(
  //     "y",
  //     l.If(
  //       l.Bool(True),
  //       l.Prim(l.Read),
  //       l.If(
  //         l.Prim(l.Cmp(l.Eq, l.Prim(l.Read), l.Int(0))),
  //         l.Int(777),
  //         l.Let("x", l.Prim(l.Read), l.Prim(l.Plus(l.Int(1), l.Var("x")))),
  //       ),
  //     ),
  //     l.Prim(l.Plus(l.Var("y"), l.Int(2))),
  //   ))

  let input =
    "(let ([y (if #t
              (read)
              (if (eq? (read) 0)
                  777
                  (let ([x (read)]) (+ 1 x))))])
    (+ y 2))"
  let assert Ok(tokens) = parse.tokens(input)
  let assert Ok(p) = parse.parse(tokens)
  let assert Ok(pt) = l.type_check_program(p)

  pt
  // |> shrink.shrink
  // |> uniquify.uniquify
  // |> remove_complex_operands.remove_complex_operands
  // |> explicate_control.explicate_control
  // |> select_instructions.select_instructions
  // |> uncover_live.uncover_live
  // |> build_interference.build_interference
  // |> allocate_registers.allocate_registers
  // |> patch_instructions.patch_instructions
  // |> generate_prelude_and_conclusion.generate_prelude_and_conclusion
  // |> generate_prelude_and_conclusion.program_to_text("main")
  // |> io.println
}
