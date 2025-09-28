import eoc/langs/l_tup as l
import gleam/list

pub fn shrink(input: l.Program) -> l.Program {
  input.body
  |> shrink_expr()
  |> l.Program
}

fn shrink_expr(expr: l.Expr) -> l.Expr {
  case expr {
    l.Bool(_) | l.Int(_) | l.Var(_) -> expr
    l.If(cond, t, e) -> l.If(shrink_expr(cond), shrink_expr(t), shrink_expr(e))
    l.Let(var, binding, body) ->
      l.Let(var, shrink_expr(binding), shrink_expr(body))
    l.Prim(op) -> shrink_op(op)
    l.Begin(stmts:, result:) ->
      l.Begin(list.map(stmts, shrink_expr), shrink_expr(result))
    l.SetBang(var:, value:) -> l.SetBang(var, shrink_expr(value))
    l.WhileLoop(condition:, body:) ->
      l.WhileLoop(shrink_expr(condition), shrink_expr(body))
    l.HasType(value:, t:) -> l.HasType(shrink_expr(value), t)
  }
}

fn shrink_op(op: l.PrimOp) -> l.Expr {
  case op {
    l.And(a, b) -> l.If(shrink_expr(a), shrink_expr(b), l.Bool(False))
    l.Or(a, b) -> l.If(shrink_expr(a), l.Bool(True), shrink_expr(b))
    l.Cmp(c, a, b) -> l.Prim(l.Cmp(c, shrink_expr(a), shrink_expr(b)))
    l.Minus(a, b) -> l.Prim(l.Minus(shrink_expr(a), shrink_expr(b)))
    l.Negate(v) -> l.Prim(l.Negate(shrink_expr(v)))
    l.Not(v) -> l.Prim(l.Not(shrink_expr(v)))
    l.Plus(a, b) -> l.Prim(l.Plus(shrink_expr(a), shrink_expr(b)))
    l.Read -> l.Prim(l.Read)
    l.Void -> l.Prim(l.Void)
    l.Vector(fields:) -> l.Prim(l.Vector(list.map(fields, shrink_expr)))
    l.VectorLength(v:) -> l.Prim(l.VectorLength(shrink_expr(v)))
    l.VectorRef(v:, index:) ->
      l.Prim(l.VectorRef(shrink_expr(v), shrink_expr(index)))
    l.VectorSet(v:, index:, value:) ->
      l.Prim(l.VectorSet(shrink_expr(v), shrink_expr(index), shrink_expr(value)))
  }
}
