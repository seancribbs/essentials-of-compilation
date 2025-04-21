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

pub fn is_callee_saved(reg: Register) -> Bool {
  case reg {
    Rsp | Rbp | Rbx | R12 | R13 | R14 | R15 -> True
    _ -> False
  }
}

pub fn is_caller_saved(reg: Register) -> Bool {
  case reg {
    Rax | Rcx | Rdx | Rsi | Rdi | R8 | R9 | R10 | R11 -> True
    _ -> False
  }
}
