import gleam/io
import langs/l_var as l
import passes/assign_homes
import passes/explicate_control
import passes/generate_prelude_and_conclusion
import passes/patch_instructions
import passes/remove_complex_operands
import passes/select_instructions
import passes/uniquify

pub fn main() {
  let p =
    l.Program(l.Let(
      "y",
      l.Let(
        "x",
        l.Int(20),
        l.Prim(l.Plus(l.Var("x"), l.Let("x", l.Int(22), l.Var("x")))),
      ),
      l.Var("y"),
    ))

  p
  |> uniquify.uniquify
  |> remove_complex_operands.remove_complex_operands
  |> explicate_control.explicate_control
  |> select_instructions.select_instructions
  |> assign_homes.assign_homes
  |> patch_instructions.patch_instructions
  |> generate_prelude_and_conclusion.generate_prelude_and_conclusion
  |> generate_prelude_and_conclusion.program_to_text("main")
  |> io.println
}
