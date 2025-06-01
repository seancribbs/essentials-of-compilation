import gleam/dict

pub type Atm {
  Int(value: Int)
  Bool(value: Bool)
  Variable(v: String)
}

pub type Cmp {
  Eq
  Lt
  Lte
  Gt
  Gte
}

pub type PrimOp {
  Read
  Neg(a: Atm)
  Not(a: Atm)
  Cmp(Cmp, a: Atm, b: Atm)
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
  Goto(label: String)
  If(cmp: Cmp, a: Atm, b: Atm, if_true: String, if_false: String)
}

pub type CProgram {
  CProgram(info: dict.Dict(String, List(String)), body: dict.Dict(String, Tail))
}
