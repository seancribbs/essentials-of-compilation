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
import gleam/dict
import gleam/set.{type Set}

pub type Register {
  Rsp
  Rbp
  Rax
  Rbx
  Rcx
  Rdx
  Rsi
  Rdi
  R8
  R9
  R10
  R11
  R12
  R13
  R14
  R15
}

pub type Arg {
  Imm(value: Int)
  Reg(reg: Register)
  // Deref(reg: Register, offset: Int)
  Var(name: String)
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
}

pub type Block {
  Block(body: List(Instr), live_after: List(Set(Location)))
}

pub type X86Program {
  X86Program(body: dict.Dict(String, Block))
}

pub type Location {
  LocReg(reg: Register)
  LocVar(name: String)
}
