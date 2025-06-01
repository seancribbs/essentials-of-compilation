// L_if => L_if (without and/or)
import eoc/langs/l_if.{
  type Expr, type PrimOp, type Program, And, Bool, Cmp, If, Int, Let, Minus,
  Negate, Not, Or, Plus, Prim, Program, Read, Var,
}

pub fn shrink(input: Program) -> Program {
  input.body
  |> shrink_expr()
  |> Program
}

fn shrink_expr(expr: Expr) -> Expr {
  case expr {
    Bool(_) | Int(_) | Var(_) -> expr
    If(cond, t, e) -> If(shrink_expr(cond), shrink_expr(t), shrink_expr(e))
    Let(var, binding, body) -> Let(var, shrink_expr(binding), shrink_expr(body))
    Prim(op) -> shrink_op(op)
  }
}

fn shrink_op(op: PrimOp) -> Expr {
  case op {
    And(a, b) -> If(shrink_expr(a), shrink_expr(b), Bool(False))
    Or(a, b) -> If(shrink_expr(a), Bool(True), shrink_expr(b))
    Cmp(c, a, b) -> Prim(Cmp(c, shrink_expr(a), shrink_expr(b)))
    Minus(a, b) -> Prim(Minus(shrink_expr(a), shrink_expr(b)))
    Negate(v) -> Prim(Negate(shrink_expr(v)))
    Not(v) -> Prim(Not(shrink_expr(v)))
    Plus(a, b) -> Prim(Plus(shrink_expr(a), shrink_expr(b)))
    Read -> Prim(Read)
  }
}
