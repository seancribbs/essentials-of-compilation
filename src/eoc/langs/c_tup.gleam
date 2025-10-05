import eoc/langs/l_tup.{type Cmp, type Type}
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
  VectorRef(v: Atm, index: Atm)
  VectorSet(v: Atm, index: Atm, value: Atm)
  VectorLength(v: Atm)
}

pub type Expr {
  Atom(atm: Atm)
  Prim(op: PrimOp)
  Allocate(amount: Int, t: Type)
  GlobalValue(var: String)
}

pub type Stmt {
  Assign(var: String, expr: Expr)
  ReadStmt
  VectorSetStmt(v: Atm, index: Atm, value: Atm)
  Collect(amount: Int)
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
