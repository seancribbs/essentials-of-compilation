import eoc/langs/l_while.{type Cmp}
import gleam/dict

pub type Atm {
  Int(value: Int)
  Bool(value: Bool)
  Variable(v: String)
  Void
}

pub type PrimOp {
  Read
  Neg(a: Atm)
  Not(a: Atm)
  Cmp(op: Cmp, a: Atm, b: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
}

pub type Expr {
  Atom(atm: Atm)
  Prim(op: PrimOp)
}

pub type Stmt {
  Assign(var: String, expr: Expr)
  ReadStmt
}

pub type Tail {
  Return(a: Expr)
  Seq(s: Stmt, t: Tail)
  Goto(label: String)
  If(cond: Expr, if_true: Tail, if_false: Tail)
}

pub type Blocks =
  dict.Dict(String, Tail)

pub type CProgram {
  CProgram(info: dict.Dict(String, List(String)), body: Blocks)
}
