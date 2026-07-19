// import eoc/langs/l_fun as l
import eoc/langs/x86_base.{type ByteReg, type Cc, type Register}
import glam/doc
import gleam/dict
import gleam/int
import gleam/list

pub type Arg {
  // $value
  Imm(value: Int)
  // %reg
  Reg(reg: Register)
  // offset(register)
  Deref(reg: Register, offset: Int)
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
  Callq(label: String)
  IndirectCallq(a: Arg)
  // TailJmp(label: Arg, arity: Int)
  IndirectJmp(a: Arg)
  Leaq(a: Arg, b: Arg)
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
  Block(body: List(Instr), is_function: Bool)
}

pub type X86Program {
  X86Program(blocks: dict.Dict(String, Block))
}

pub fn new_block() -> Block {
  Block([], False)
}

pub fn format_program(input: X86Program) -> doc.Document {
  input.blocks
  |> dict.to_list()
  |> list.map(fn(p) { format_block(p.0, p.1) })
  |> doc.concat_join(with: [doc.line, doc.line])
}

pub fn format_block(name: String, block: Block) -> doc.Document {
  let prefix = case block.is_function {
    True ->
      doc.concat([doc.from_string("\t.globl .align 8 " <> name), doc.line])
    _ -> doc.empty
  }
  let label =
    doc.concat([
      doc.from_string(name <> ":"),
      doc.line,
    ])

  block.body
  |> list.map(format_instr)
  |> doc.concat_join(with: [doc.line])
  |> doc.prepend(label)
  |> doc.nest(2)
  |> doc.group()
  |> doc.prepend(prefix)
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
    Callq(label:) -> doc.from_string("callq " <> label)
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
    Leaq(a:, b:) ->
      doc.concat([
        doc.from_string("leaq "),
        format_arg(a),
        comma,
        format_arg(b),
      ])
    IndirectJmp(a:) ->
      doc.concat([
        doc.from_string("jmp *"),
        format_arg(a),
      ])
    IndirectCallq(a:) ->
      doc.concat([
        doc.from_string("callq *"),
        format_arg(a),
      ])
  }
}

fn format_arg(a: Arg) -> doc.Document {
  case a {
    Deref(reg:, offset:) ->
      // offset(reg)
      doc.concat([
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
  }
}
