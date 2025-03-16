import gleam/dict

pub type Atm {
  Int(value: Int)
  Variable(v: String)
}

pub type PrimOp {
  Read
  Neg(a: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
}

pub type Expr {
  Atom(atm: Atm)
  Prim(op: PrimOp)
}

pub type Stmt {
  Assign(var: String, expr: Expr)
}

pub type Tail {
  Return(a: Expr)
  Seq(s: Stmt, t: Tail)
}

pub type CProgram {
  CProgram(info: dict.Dict(String, List(String)), body: dict.Dict(String, Tail))
}
