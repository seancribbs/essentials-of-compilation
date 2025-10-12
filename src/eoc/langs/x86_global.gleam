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
import eoc/langs/x86_base.{type ByteReg, type Cc, type Location, type Register}
import gleam/dict
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
  // label(%rip)
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
  X86Program(body: dict.new(), conflicts: interference_graph.new())
}

pub fn new_block() -> Block {
  Block([], set.new(), [])
}

pub type X86Program {
  X86Program(
    body: dict.Dict(String, Block),
    conflicts: interference_graph.Graph,
  )
}
