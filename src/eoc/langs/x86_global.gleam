//       .globl main
// main:
//     movq  $10, %rax
//     addq  $32, %rax
//     retq

// RBP - lower bound of variables in scope
// RSP - upper bound of variables in scope

// (+ 52 (- 10))
// start:
//     movq $10, -8(%rbp)
//     negq -8(%rbp)
//     movq -8(%rbp), %rax
//     addq $52, %rax
//     jmp conclusion
//
//    .globl main
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
import eoc/interference_graph
import eoc/langs/l_tup as l
import eoc/langs/x86_base.{type ByteReg, type Cc, type Location, type Register}
import glam/doc
import gleam/dict
import gleam/int
import gleam/list
import gleam/set.{type Set}

pub type Arg {
  // $value
  Imm(value: Int)
  // %reg
  Reg(reg: Register)
  // offset(register)
  Deref(reg: Register, offset: Int)
  // var (gets replaced in register allocation)
  Var(name: String)
  // labels(%rip)
  Global(label: String)
}

pub type Instr {
  Addq(a: Arg, b: Arg)
  Subq(a: Arg, b: Arg)
  Negq(a: Arg)
  Movq(a: Arg, b: Arg)
  Pushq(a: Arg)
  Popq(a: Arg)
  Callq(label: String, arity: Int)
  Retq
  Jmp(label: String)
  Xorq(a: Arg, b: Arg)
  Cmpq(a: Arg, b: Arg)
  Set(cmp: Cc, arg: ByteReg)
  Movzbq(a: ByteReg, b: Arg)
  JmpIf(cmp: Cc, label: String)
  Andq(a: Arg, b: Arg)
  Sarq(a: Arg, b: Arg)
}

pub type Block {
  Block(
    body: List(Instr),
    live_before: Set(Location),
    live_after: List(Set(Location)),
  )
}

pub fn new_program() -> X86Program {
  X86Program(
    body: dict.new(),
    types: dict.new(),
    conflicts: interference_graph.new(),
  )
}

pub fn new_block() -> Block {
  Block([], set.new(), [])
}

pub type X86Program {
  X86Program(
    body: dict.Dict(String, Block),
    types: dict.Dict(String, l.Type),
    conflicts: interference_graph.Graph,
  )
}

pub fn format_program(input: X86Program) -> doc.Document {
  input.body
  |> dict.to_list
  |> list.map(format_block)
  |> doc.concat_join(with: [doc.line, doc.line])
}

pub fn format_block(block: #(String, Block)) -> doc.Document {
  let #(block_name, block_body) = block
  let label =
    doc.concat([
      doc.from_string(block_name <> ":"),
      doc.space,
      doc.from_string("# live before: "),
      format_live_set(block_body.live_before),
      doc.line,
    ])

  block_body.body
  |> list.map(format_instr)
  |> doc.concat_join(with: [doc.line])
  |> doc.prepend(label)
  |> doc.nest(2)
  |> doc.group()
}

fn format_live_set(set: Set(Location)) -> doc.Document {
  set
  |> set.map(format_location)
  |> set.to_list()
  |> doc.concat_join(with: [doc.from_string(", ")])
  |> doc.prepend(doc.from_string("{"))
  |> doc.append(doc.from_string("}"))
}

fn format_location(loc: Location) -> doc.Document {
  case loc {
    x86_base.LocReg(reg:) -> x86_base.format_register(reg)
    x86_base.LocVar(name:) -> doc.from_string(name)
  }
}

pub fn format_instr(instr: Instr) -> doc.Document {
  let comma = doc.from_string(", ")
  case instr {
    Addq(a:, b:) ->
      doc.concat([doc.from_string("addq "), format_arg(a), comma, format_arg(b)])
    Andq(a:, b:) ->
      doc.concat([doc.from_string("andq "), format_arg(a), comma, format_arg(b)])
    Cmpq(a:, b:) ->
      doc.concat([doc.from_string("cmpq "), format_arg(a), comma, format_arg(b)])
    Movq(a:, b:) ->
      doc.concat([doc.from_string("movq "), format_arg(a), comma, format_arg(b)])
    Movzbq(a:, b:) ->
      doc.concat([
        doc.from_string("movzbq "),
        x86_base.format_bytereg(a),
        comma,
        format_arg(b),
      ])
    Negq(a:) -> doc.concat([doc.from_string("negq "), format_arg(a)])
    Popq(a:) -> doc.concat([doc.from_string("popq "), format_arg(a)])
    Pushq(a:) -> doc.concat([doc.from_string("pushq "), format_arg(a)])
    Sarq(a:, b:) ->
      doc.concat([doc.from_string("sarq "), format_arg(a), comma, format_arg(b)])
    Subq(a:, b:) ->
      doc.concat([doc.from_string("subq "), format_arg(a), comma, format_arg(b)])
    Xorq(a:, b:) ->
      doc.concat([doc.from_string("xorq "), format_arg(a), comma, format_arg(b)])
    Set(cmp:, arg:) ->
      doc.concat([
        doc.from_string(
          "set"
          <> case cmp {
            x86_base.E -> "e"
            x86_base.G -> "g"
            x86_base.Ge -> "ge"
            x86_base.L -> "l"
            x86_base.Le -> "le"
          }
          <> " ",
        ),
        x86_base.format_bytereg(arg),
      ])
    Callq(label:, arity: _) -> doc.from_string("callq " <> label)
    Jmp(label:) -> doc.from_string("jmp " <> label)
    JmpIf(cmp:, label:) ->
      doc.from_string(
        case cmp {
          x86_base.E -> "je"
          x86_base.G -> "jg"
          x86_base.Ge -> "jge"
          x86_base.L -> "jl"
          x86_base.Le -> "jle"
        }
        <> " "
        <> label,
      )
    Retq -> doc.from_string("retq")
  }
}

fn format_arg(a: Arg) -> doc.Document {
  case a {
    Deref(reg:, offset:) ->
      doc.concat([
        // offset(reg)
        doc.from_string(int.to_string(offset)),
        doc.from_string("("),
        x86_base.format_register(reg),
        doc.from_string(")"),
      ])
    Global(label:) -> doc.from_string(label <> "(%rip)")
    Imm(value:) ->
      doc.concat([
        doc.from_string("$"),
        doc.from_string(int.to_string(value)),
      ])
    Reg(reg:) -> x86_base.format_register(reg)
    Var(name:) -> doc.from_string(name)
  }
}
