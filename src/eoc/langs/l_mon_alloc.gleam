import eoc/langs/l_tup.{type Cmp, type Type}

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
  VectorLength(v: Atm)
  VectorRef(v: Atm, index: Atm)
  VectorSet(v: Atm, index: Atm, value: Atm)
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
  Collect(amount: Int)
  Allocate(amount: Int, t: Type)
  GlobalValue(name: String)
}

pub type Program {
  Program(body: Expr)
}
