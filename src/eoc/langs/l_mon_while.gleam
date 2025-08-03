import eoc/langs/l_while.{type Cmp}

pub type Atm {
  Int(value: Int)
  Var(name: String)
  Bool(value: Bool)
  Void
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
  GetBang(var: String)
  SetBang(var: String, value: Expr)
  Begin(stmts: List(Expr), result: Expr)
  WhileLoop(condition: Expr, body: Expr)
}

pub type Program {
  Program(body: Expr)
}
