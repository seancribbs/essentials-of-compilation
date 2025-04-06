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

pub type Location {
  LocReg(reg: Register)
  LocVar(name: String)
}
