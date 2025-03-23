import eoc/langs/x86_int as x86
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/string
import gleam/string_tree

pub fn generate_prelude_and_conclusion(input: x86.X86Program) -> x86.X86Program {
  let main = generate_main(input)
  let conclusion = generate_conclusion(input)
  input.body
  |> dict.insert("main", main)
  |> dict.insert("conclusion", conclusion)
  |> x86.X86Program
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

fn generate_main(input: x86.X86Program) -> x86.Block {
  let assert Ok(start_block) = dict.get(input.body, "start")
  x86.Block(
    [
      x86.Pushq(x86.Reg(x86.Rbp)),
      x86.Movq(x86.Reg(x86.Rsp), x86.Reg(x86.Rbp)),
      x86.Subq(x86.Imm(start_block.frame_size), x86.Reg(x86.Rsp)),
      x86.Jmp("start"),
    ],
    0,
  )
}

fn generate_conclusion(input: x86.X86Program) -> x86.Block {
  let assert Ok(start_block) = dict.get(input.body, "start")
  x86.Block(
    [
      x86.Addq(x86.Imm(start_block.frame_size), x86.Reg(x86.Rsp)),
      x86.Popq(x86.Reg(x86.Rbp)),
      x86.Retq,
    ],
    0,
  )
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

fn reg_to_text(arg: x86.Register) -> string_tree.StringTree {
  let r = case arg {
    x86.R10 -> "r10"
    x86.R11 -> "r11"
    x86.R12 -> "r12"
    x86.R13 -> "r13"
    x86.R14 -> "r14"
    x86.R15 -> "r15"
    x86.R8 -> "r8"
    x86.R9 -> "r9"
    x86.Rax -> "rax"
    x86.Rbp -> "rbp"
    x86.Rbx -> "rbx"
    x86.Rcx -> "rcx"
    x86.Rdi -> "rdi"
    x86.Rdx -> "rdx"
    x86.Rsi -> "rsi"
    x86.Rsp -> "rsp"
  }
  string_tree.from_strings(["%", r])
}

fn indent() -> string_tree.StringTree {
  string_tree.from_string("    ")
}
