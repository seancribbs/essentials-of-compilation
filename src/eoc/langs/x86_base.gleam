import glam/doc
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

pub type ByteReg {
  Ah
  Al
  Bh
  Bl
  Ch
  Cl
  Dh
  Dl
}

pub type Cc {
  E
  L
  Le
  G
  Ge
}

pub type Location {
  LocReg(reg: Register)
  LocVar(name: String)
}

pub const callee_saved_registers: List(Register) = [
  Rsp,
  Rbp,
  Rbx,
  R12,
  R13,
  R14,
  R15,
]

pub const caller_saved_registers: List(Register) = [
  Rax,
  Rcx,
  Rdx,
  Rsi,
  Rdi,
  R8,
  R9,
  R10,
  R11,
]

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

pub fn bytereg_to_quad(br: ByteReg) -> Register {
  case br {
    Ah | Al -> Rax
    Bh | Bl -> Rbx
    Ch | Cl -> Rcx
    Dh | Dl -> Rdx
  }
}

pub fn format_register(r: Register) -> doc.Document {
  case r {
    R10 -> doc.from_string("%r10")
    R11 -> doc.from_string("%r11")
    R12 -> doc.from_string("%r12")
    R13 -> doc.from_string("%r13")
    R14 -> doc.from_string("%r14")
    R15 -> doc.from_string("%r15")
    R8 -> doc.from_string("%r8")
    R9 -> doc.from_string("%r9")
    Rax -> doc.from_string("%rax")
    Rbp -> doc.from_string("%rbp")
    Rbx -> doc.from_string("%rbx")
    Rcx -> doc.from_string("%rcx")
    Rdi -> doc.from_string("%rdi")
    Rdx -> doc.from_string("%rdx")
    Rsi -> doc.from_string("%rsi")
    Rsp -> doc.from_string("%rsp")
  }
}

pub fn format_bytereg(r: ByteReg) -> doc.Document {
  case r {
    Ah -> doc.from_string("%ah")
    Al -> doc.from_string("%al")
    Bh -> doc.from_string("%bh")
    Bl -> doc.from_string("%bl")
    Ch -> doc.from_string("%ch")
    Cl -> doc.from_string("%cl")
    Dh -> doc.from_string("%dh")
    Dl -> doc.from_string("%dl")
  }
}
