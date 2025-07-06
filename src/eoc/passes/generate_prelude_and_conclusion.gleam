import eoc/langs/x86_base.{Rbp, Rsp}
import eoc/langs/x86_if as x86
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/set
import gleam/string
import gleam/string_tree

pub fn generate_prelude_and_conclusion(input: x86.X86Program) -> x86.X86Program {
  let alignment = compute_frame_alignment(input)
  let saved_regs = get_saved_registers(input)
  let main = generate_main(alignment, saved_regs)
  let conclusion = generate_conclusion(alignment, saved_regs)

  let body =
    input.body
    |> dict.insert("main", main)
    |> dict.insert("conclusion", conclusion)

  x86.X86Program(..input, body:)
}

// main:
//    pushq %rbp
//    movq  %rsp, %rbp
//    subq  $16, %rsp
//    jmp start
//
// conclusion:
//    addq  $16, %rsp
//    popq  %rbp
//    retq

fn align(bytes: Int) -> Int {
  case bytes % 16 {
    0 -> bytes
    _ -> { bytes / 16 + 1 } * 16
  }
}

fn compute_frame_alignment(input: x86.X86Program) -> Int {
  // let assert Ok(start_block) = dict.get(input.body, "start")
  // Add one because we always save %rbp!!!
  let saved_regs = set.size(input.used_callee) + 1
  // A= align(8S + 8C) – 8C
  align(8 * input.stack_vars + 8 * saved_regs) - { 8 * saved_regs }
}

fn get_saved_registers(input: x86.X86Program) -> List(x86_base.Register) {
  set.to_list(input.used_callee)
}

fn generate_main(
  alignment: Int,
  registers: List(x86_base.Register),
) -> x86.Block {
  let pushes = list.map([Rbp, ..registers], fn(r) { x86.Pushq(x86.Reg(r)) })
  let aligner = case alignment {
    0 -> []
    _ -> [x86.Subq(x86.Imm(alignment), x86.Reg(Rsp))]
  }

  let instrs =
    pushes
    |> list.append([x86.Movq(x86.Reg(Rsp), x86.Reg(Rbp))])
    |> list.append(aligner)
    |> list.append([x86.Jmp("start")])

  x86.Block(instrs)
}

fn generate_conclusion(
  alignment: Int,
  registers: List(x86_base.Register),
) -> x86.Block {
  let pops =
    [Rbp, ..registers]
    |> list.map(fn(r) { x86.Popq(x86.Reg(r)) })
    |> list.reverse()

  let aligner = case alignment {
    0 -> []
    _ -> [x86.Addq(x86.Imm(alignment), x86.Reg(Rsp))]
  }

  let instrs =
    aligner
    |> list.append(pops)
    |> list.append([x86.Retq])

  x86.Block(instrs)
}

pub fn program_to_text(input: x86.X86Program, entry: String) -> String {
  input.body
  |> dict.to_list()
  |> list.sort(fn(a, b) { string.compare(pair.first(a), pair.first(b)) })
  |> list.map(block_to_text(_, entry))
  |> string_tree.join("\n\n")
  |> string_tree.to_string()
}

fn block_to_text(
  kv: #(String, x86.Block),
  entry: String,
) -> string_tree.StringTree {
  let #(label, block) = kv
  let prelude = case label == entry {
    True -> [
      "    .globl " |> string_tree.from_string() |> string_tree.append(label),
      label |> string_tree.from_string() |> string_tree.append(":"),
    ]
    False -> [label |> string_tree.from_string() |> string_tree.append(":")]
  }

  let instrs = list.map(block.body, instr_to_text)

  prelude
  |> list.append(instrs)
  |> string_tree.join("\n")
}

fn instr_to_text(instr: x86.Instr) -> string_tree.StringTree {
  let text = case instr {
    x86.Addq(a, b) ->
      [
        string_tree.from_string("addq "),
        arg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()
    x86.Callq(l, _) ->
      string_tree.from_string("callq ") |> string_tree.append(l)
    x86.Jmp(s) -> string_tree.from_string("jmp ") |> string_tree.append(s)
    x86.Movq(a, b) ->
      [
        string_tree.from_string("movq "),
        arg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()
    x86.Negq(a) ->
      string_tree.join([string_tree.from_string("negq"), arg_to_text(a)], " ")
    x86.Popq(a) ->
      string_tree.join([string_tree.from_string("popq"), arg_to_text(a)], " ")
    x86.Pushq(a) ->
      string_tree.join([string_tree.from_string("pushq"), arg_to_text(a)], " ")
    x86.Retq -> string_tree.from_string("retq")
    x86.Subq(a, b) ->
      [
        string_tree.from_string("subq "),
        arg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()
    x86.Cmpq(a:, b:) ->
      [
        string_tree.from_string("cmpq "),
        arg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()
    x86.Xorq(a:, b:) ->
      [
        string_tree.from_string("xorq "),
        arg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()
    x86.Movzbq(a:, b:) ->
      [
        string_tree.from_string("movzbq "),
        bytereg_to_text(a),
        string_tree.from_string(", "),
        arg_to_text(b),
      ]
      |> string_tree.concat()

    x86.JmpIf(cmp:, label:) ->
      case cmp {
        x86_base.E -> string_tree.from_string("je ")
        x86_base.G -> string_tree.from_string("jg ")
        x86_base.Ge -> string_tree.from_string("jge ")
        x86_base.L -> string_tree.from_string("jl ")
        x86_base.Le -> string_tree.from_string("jle ")
      }
      |> string_tree.append(label)
    x86.Set(cmp:, arg:) ->
      case cmp {
        x86_base.E -> string_tree.from_string("sete ")
        x86_base.G -> string_tree.from_string("setg ")
        x86_base.Ge -> string_tree.from_string("setge ")
        x86_base.L -> string_tree.from_string("setl ")
        x86_base.Le -> string_tree.from_string("setle ")
      }
      |> string_tree.append_tree(bytereg_to_text(arg))
  }

  [indent(), text] |> string_tree.concat()
}

fn arg_to_text(arg: x86.Arg) -> string_tree.StringTree {
  case arg {
    x86.Imm(i) ->
      string_tree.from_string("$") |> string_tree.append(int.to_string(i))
    x86.Reg(r) -> reg_to_text(r)
    x86.Deref(r, offset) ->
      offset
      |> int.to_string()
      |> string_tree.from_string()
      |> string_tree.append("(")
      |> string_tree.append_tree(reg_to_text(r))
      |> string_tree.append(")")
  }
}

fn bytereg_to_text(arg: x86_base.ByteReg) -> string_tree.StringTree {
  let r = case arg {
    x86_base.Ah -> "ah"
    x86_base.Al -> "al"
    x86_base.Bh -> "bh"
    x86_base.Bl -> "bl"
    x86_base.Ch -> "ch"
    x86_base.Cl -> "cl"
    x86_base.Dh -> "dh"
    x86_base.Dl -> "dl"
  }
  string_tree.from_strings(["%", r])
}

fn reg_to_text(arg: x86_base.Register) -> string_tree.StringTree {
  let r = case arg {
    x86_base.R10 -> "r10"
    x86_base.R11 -> "r11"
    x86_base.R12 -> "r12"
    x86_base.R13 -> "r13"
    x86_base.R14 -> "r14"
    x86_base.R15 -> "r15"
    x86_base.R8 -> "r8"
    x86_base.R9 -> "r9"
    x86_base.Rax -> "rax"
    x86_base.Rbp -> "rbp"
    x86_base.Rbx -> "rbx"
    x86_base.Rcx -> "rcx"
    x86_base.Rdi -> "rdi"
    x86_base.Rdx -> "rdx"
    x86_base.Rsi -> "rsi"
    x86_base.Rsp -> "rsp"
  }
  string_tree.from_strings(["%", r])
}

fn indent() -> string_tree.StringTree {
  string_tree.from_string("    ")
}
