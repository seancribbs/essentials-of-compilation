pub type Atm {
  Int(value: Int)
  Var(name: String)
}

pub type PrimOp {
  Read
  Negate(value: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
}

pub type Expr {
  Atomic(value: Atm)
  Prim(op: PrimOp)
  Let(var: String, binding: Expr, expr: Expr)
}

pub type Program {
  Program(body: Expr)
}
