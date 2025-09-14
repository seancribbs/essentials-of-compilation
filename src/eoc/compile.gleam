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
import eoc/passes/uncover_get
import eoc/passes/uncover_live
import eoc/passes/uniquify

import gleam/result
import gleam/string

pub fn interpret(input: String) -> Result(String, String) {
  // use tokens <- result.try(result.map_error(parse.tokens(input), string.inspect))
  // use program <- result.map(result.map_error(
  //   parse.parse(tokens),
  //   string.inspect,
  // ))
  // case l.interpret(program) {
  //   l.BoolValue(v:) -> string.inspect(v)
  //   l.IntValue(v:) -> string.inspect(v)
  //   l.VoidValue -> "void"
  // }
  Error("Not implemented")
}

pub fn compile(input: String) -> Result(String, String) {
  Error("Not implemented")
  // use tokens <- result.try(result.map_error(parse.tokens(input), string.inspect))
  // use program <- result.try(result.map_error(
  //   parse.parse(tokens),
  //   string.inspect,
  // ))
  // use pt <- result.map(result.map_error(
  //   l.type_check_program(program),
  //   string.inspect,
  // ))

  // pt
  // |> shrink.shrink
  // |> uniquify.uniquify
  // |> uncover_get.uncover_get
  // |> remove_complex_operands.remove_complex_operands
  // |> explicate_control.explicate_control
  // |> select_instructions.select_instructions
  // |> uncover_live.uncover_live
  // |> build_interference.build_interference
  // |> allocate_registers.allocate_registers
  // |> patch_instructions.patch_instructions
  // |> generate_prelude_and_conclusion.generate_prelude_and_conclusion
  // |> generate_prelude_and_conclusion.program_to_text("main")
}
