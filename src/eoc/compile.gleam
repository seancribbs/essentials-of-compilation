import eoc/langs/c_tup as c
import eoc/langs/l_tup as l
import eoc/langs/x86_global as x86
import eoc/passes/allocate_registers
import eoc/passes/generate_prelude_and_conclusion
import eoc/passes/patch_instructions
import eoc/passes/select_instructions
import eoc/passes/uncover_live

// import eoc/passes/allocate_registers
// import eoc/passes/build_interference
import eoc/passes/explicate_control
import eoc/passes/expose_allocation

// import eoc/passes/generate_prelude_and_conclusion
import eoc/passes/parse

// import eoc/passes/patch_instructions
import eoc/passes/remove_complex_operands

// import eoc/passes/select_instructions
import eoc/passes/shrink
import eoc/passes/uncover_get

// import eoc/passes/uncover_live
import eoc/passes/uniquify
import glam/doc
import gleam/int

import gleam/result
import gleam/string

pub type Pass {
  Parse
  TypeCheck
  Shrink
  Uniquify
  ExplicateControl
  SelectInstructions
  UncoverLive
  AllocateRegisters
  PatchInstructions
  GeneratePreludeAndConclusion
}

pub const default_last_pass: Pass = GeneratePreludeAndConclusion

pub const pass_order: List(Pass) = [
  Parse,
  TypeCheck,
  Shrink,
  Uniquify,
  ExplicateControl,
  SelectInstructions,
  UncoverLive,
  AllocateRegisters,
  PatchInstructions,
  GeneratePreludeAndConclusion,
]

pub fn pass_to_string(p: Pass) -> String {
  case p {
    Parse -> "parse"
    TypeCheck -> "type_check"
    Shrink -> "shrink"
    Uniquify -> "uniquify"
    ExplicateControl -> "explicate_control"
    SelectInstructions -> "select_instructions"
    UncoverLive -> "uncover_live"
    AllocateRegisters -> "allocate_registers"
    PatchInstructions -> "patch_instructions"
    GeneratePreludeAndConclusion -> "generate_prelude_and_conclusion"
  }
}

pub fn string_to_pass(s: String) -> Pass {
  case s {
    "explicate_control" -> ExplicateControl
    "shrink" -> Shrink
    "uniquify" -> Uniquify
    "parse" -> Parse
    "type_check" -> TypeCheck
    "select_instructions" -> SelectInstructions
    "uncover_live" -> UncoverLive
    "allocate_registers" -> AllocateRegisters
    "patch_instructions" -> PatchInstructions
    "generate_prelude_and_conclusion" -> GeneratePreludeAndConclusion
    _ -> default_last_pass
  }
}

pub fn interpret(input: String) -> Result(String, String) {
  use tokens <- result.try(result.map_error(parse.tokens(input), string.inspect))
  use program <- result.map(result.map_error(
    parse.parse(tokens),
    string.inspect,
  ))
  case l.interpret(program) {
    l.BoolValue(v:) -> string.inspect(v)
    l.IntValue(v:) -> string.inspect(v)
    l.VoidValue -> "void"
    l.HeapRef(i:) -> "(heap-ref " <> int.to_string(i) <> ")"
  }
}

pub fn compile(input: String, pass: Pass) -> Result(String, String) {
  use tokens <- result.try(result.map_error(parse.tokens(input), string.inspect))
  use program <- result.try(result.map_error(
    parse.parse(tokens),
    string.inspect,
  ))
  case pass {
    Parse ->
      program
      |> l.format_program()
      |> doc.to_string(80)
      |> Ok

    TypeCheck -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> l.format_program()
      |> doc.to_string(80)
    }

    Shrink -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> l.format_program()
      |> doc.to_string(80)
    }

    Uniquify -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> l.format_program()
      |> doc.to_string(80)
    }

    // ==== a few passes later...
    ExplicateControl -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> c.format_program()
      |> doc.to_string(80)
    }
    SelectInstructions -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> select_instructions.select_instructions
      |> x86.format_program()
      |> doc.to_string(80)
    }
    UncoverLive -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> select_instructions.select_instructions
      |> uncover_live.uncover_live
      |> x86.format_program()
      |> doc.to_string(80)
    }
    AllocateRegisters -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> select_instructions.select_instructions
      |> uncover_live.uncover_live
      |> allocate_registers.allocate_registers
      |> x86.format_program()
      |> doc.to_string(80)
    }
    PatchInstructions -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> select_instructions.select_instructions
      |> uncover_live.uncover_live
      |> allocate_registers.allocate_registers
      |> patch_instructions.patch_instructions
      |> x86.format_program()
      |> doc.to_string(80)
    }
    GeneratePreludeAndConclusion -> {
      use p <- result.map(result.map_error(
        l.type_check_program(program),
        string.inspect,
      ))
      p
      |> shrink.shrink
      |> uniquify.uniquify
      |> expose_allocation.expose_allocation
      |> uncover_get.uncover_get
      |> remove_complex_operands.remove_complex_operands
      |> explicate_control.explicate_control
      |> select_instructions.select_instructions
      |> uncover_live.uncover_live
      |> allocate_registers.allocate_registers
      |> patch_instructions.patch_instructions
      |> generate_prelude_and_conclusion.generate_prelude_and_conclusion
      |> x86.format_program()
      |> doc.to_string(80)
    }
  }
}
