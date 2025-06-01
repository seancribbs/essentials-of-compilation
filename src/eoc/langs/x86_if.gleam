import eoc/langs/x86_base.{type ByteReg, type Register}
import gleam/dict
import gleam/set

pub type Arg {
  Imm(value: Int)
  Reg(reg: Register)
  Deref(reg: Register, offset: Int)
  // Note: ByteReg is only used in the `set` instruction, so it doesn't
  // need to be a regular argument.
  //
  // ByteReg(reg: ByteReg)
}

pub type Cc {
  E
  L
  Le
  G
  Ge
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
}

pub type Block {
  Block(body: List(Instr), stack_vars: Int, used_callee: set.Set(Register))
}

pub type X86Program {
  X86Program(body: dict.Dict(String, Block))
}
