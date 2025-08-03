import gleam/list
import gleam/set

import eoc/langs/l_while as l
import eoc/langs/l_while_get as l_get

pub fn uncover_get(input: l.Program) -> l_get.Program {
  let muts = collect_set_bang(input.body)
  let body = uncover_get_expr(input.body, muts)
  l_get.Program(body)
}

fn uncover_get_expr(e: l.Expr, vars: set.Set(String)) -> l_get.Expr {
  case e {
    l.Bool(value:) -> l_get.Bool(value)
    l.Int(value:) -> l_get.Int(value)

    l.Var(name:) -> {
      case set.contains(vars, name) {
        True -> l_get.GetBang(name)
        False -> l_get.Var(name)
      }
    }

    l.Begin(stmts:, result:) -> {
      let s2 = list.map(stmts, uncover_get_expr(_, vars))
      l_get.Begin(s2, uncover_get_expr(result, vars))
    }

    l.If(condition:, if_true:, if_false:) ->
      l_get.If(
        uncover_get_expr(condition, vars),
        uncover_get_expr(if_true, vars),
        uncover_get_expr(if_false, vars),
      )
    l.Let(var:, binding:, expr:) ->
      l_get.Let(
        var,
        uncover_get_expr(binding, vars),
        uncover_get_expr(expr, vars),
      )

    l.SetBang(var:, value:) -> l_get.SetBang(var, uncover_get_expr(value, vars))
    l.WhileLoop(condition:, body:) ->
      l_get.WhileLoop(
        uncover_get_expr(condition, vars),
        uncover_get_expr(body, vars),
      )

    l.Prim(op: l.Read) -> l_get.Prim(l_get.Read)
    l.Prim(op: l.And(a:, b:)) ->
      l_get.Prim(l_get.And(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Cmp(op:, a:, b:)) ->
      l_get.Prim(l_get.Cmp(
        op,
        uncover_get_expr(a, vars),
        uncover_get_expr(b, vars),
      ))
    l.Prim(op: l.Minus(a:, b:)) ->
      l_get.Prim(l_get.Minus(
        uncover_get_expr(a, vars),
        uncover_get_expr(b, vars),
      ))
    l.Prim(op: l.Negate(value:)) ->
      l_get.Prim(l_get.Negate(uncover_get_expr(value, vars)))
    l.Prim(op: l.Not(a:)) -> l_get.Prim(l_get.Not(uncover_get_expr(a, vars)))
    l.Prim(op: l.Or(a:, b:)) ->
      l_get.Prim(l_get.Or(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Plus(a:, b:)) ->
      l_get.Prim(l_get.Plus(
        uncover_get_expr(a, vars),
        uncover_get_expr(b, vars),
      ))
    l.Prim(op: l.Void) -> l_get.Prim(l_get.Void)
  }
}

pub fn collect_set_bang(e: l.Expr) -> set.Set(String) {
  case e {
    l.Var(name: _) -> set.new()
    l.Int(value: _) -> set.new()
    l.Bool(value: _) -> set.new()
    l.Let(var: _, binding:, expr:) ->
      set.union(collect_set_bang(binding), collect_set_bang(expr))
    l.SetBang(var:, value:) ->
      set.union(set.from_list([var]), collect_set_bang(value))
    l.Begin(stmts:, result:) ->
      set.union(
        list.fold(stmts, set.new(), fn(acc, stmt) {
          set.union(acc, collect_set_bang(stmt))
        }),
        collect_set_bang(result),
      )
    l.If(condition:, if_true:, if_false:) ->
      list.fold([condition, if_true, if_false], set.new(), fn(acc, expr) {
        set.union(acc, collect_set_bang(expr))
      })
    l.WhileLoop(condition:, body:) -> {
      set.union(collect_set_bang(condition), collect_set_bang(body))
    }

    l.Prim(op: l.Read) -> set.new()
    l.Prim(op: l.And(a:, b:)) ->
      set.union(collect_set_bang(a), collect_set_bang(b))
    l.Prim(op: l.Cmp(op: _, a:, b:)) ->
      set.union(collect_set_bang(a), collect_set_bang(b))
    l.Prim(op: l.Minus(a:, b:)) ->
      set.union(collect_set_bang(a), collect_set_bang(b))
    l.Prim(op: l.Negate(value:)) -> collect_set_bang(value)
    l.Prim(op: l.Not(a:)) -> collect_set_bang(a)
    l.Prim(op: l.Or(a:, b:)) ->
      set.union(collect_set_bang(a), collect_set_bang(b))
    l.Prim(op: l.Plus(a:, b:)) ->
      set.union(collect_set_bang(a), collect_set_bang(b))
    l.Prim(op: l.Void) -> set.new()
  }
}
