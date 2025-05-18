import gleam/int
import gleam/order
import gleam/string

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

pub fn compare_location(a: Location, b: Location) -> order.Order {
  case a, b {
    LocReg(_), LocVar(_) -> order.Lt
    LocVar(_), LocReg(_) -> order.Gt
    LocVar(v1), LocVar(v2) -> string.compare(v1, v2)
    LocReg(r1), LocReg(r2) ->
      int.compare(register_to_rank(r1), register_to_rank(r2))
  }
}

fn register_to_rank(r: Register) -> Int {
  case r {
    Rax -> -1
    Rsp -> -2
    Rbp -> -3
    R11 -> -4
    R15 -> -5
    Rcx -> 0
    Rdx -> 1
    Rsi -> 2
    Rdi -> 3
    R8 -> 4
    R9 -> 5
    R10 -> 6
    Rbx -> 7
    R12 -> 8
    R13 -> 9
    R14 -> 10
  }
}
