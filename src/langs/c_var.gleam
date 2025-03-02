import gleam/dict

pub type Var {
  Var(name: String)
}

pub type Atm {
  Int(value: Int)
  Variable(v: Var)
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
  Assign(var: Var, expr: Expr)
}

pub type Tail {
  Return(e: Expr)
  Seq(s: Stmt, t: Tail)
}

pub type CProgram {
  CProgram(info: dict.Dict(String, List(Var)))
}
