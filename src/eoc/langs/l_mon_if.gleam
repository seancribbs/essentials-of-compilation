import eoc/langs/l_if.{type Cmp}

pub type Atm {
  Int(value: Int)
  Var(name: String)
  Bool(value: Bool)
}

pub type PrimOp {
  Read
  Negate(value: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
  Not(value: Atm)
  Cmp(op: Cmp, a: Atm, b: Atm)
}

pub type Expr {
  Atomic(value: Atm)
  Prim(op: PrimOp)
  Let(var: String, binding: Expr, expr: Expr)
  If(cond: Expr, if_true: Expr, if_false: Expr)
}

pub type Program {
  Program(body: Expr)
}
