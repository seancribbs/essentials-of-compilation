import gleam/list
import gleam/set

import eoc/langs/l_alloc as l

pub fn uncover_get(input: l.Program) -> l.Program {
  let muts = collect_set_bang(input.body)
  let body = uncover_get_expr(input.body, muts)
  l.Program(body)
}

fn uncover_get_expr(e: l.Expr, vars: set.Set(String)) -> l.Expr {
  case e {
    l.GetBang(_) -> panic as "get! should not exist at this step"

    l.Bool(_) | l.Int(_) | l.Allocate(_, _) | l.Collect(_) | l.GlobalValue(_) ->
      e

    l.Var(name:) -> {
      case set.contains(vars, name) {
        True -> l.GetBang(name)
        False -> l.Var(name)
      }
    }

    l.Begin(stmts:, result:) -> {
      let s2 = list.map(stmts, uncover_get_expr(_, vars))
      l.Begin(s2, uncover_get_expr(result, vars))
    }

    l.If(condition:, if_true:, if_false:) ->
      l.If(
        uncover_get_expr(condition, vars),
        uncover_get_expr(if_true, vars),
        uncover_get_expr(if_false, vars),
      )
    l.Let(var:, binding:, expr:) ->
      l.Let(var, uncover_get_expr(binding, vars), uncover_get_expr(expr, vars))

    l.SetBang(var:, value:) -> l.SetBang(var, uncover_get_expr(value, vars))
    l.WhileLoop(condition:, body:) ->
      l.WhileLoop(
        uncover_get_expr(condition, vars),
        uncover_get_expr(body, vars),
      )

    l.HasType(value:, t:) -> l.HasType(uncover_get_expr(value, vars), t)

    l.Prim(op: l.Read) -> l.Prim(l.Read)
    l.Prim(op: l.And(a:, b:)) ->
      l.Prim(l.And(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Cmp(op:, a:, b:)) ->
      l.Prim(l.Cmp(op, uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Minus(a:, b:)) ->
      l.Prim(l.Minus(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Negate(value:)) ->
      l.Prim(l.Negate(uncover_get_expr(value, vars)))
    l.Prim(op: l.Not(a:)) -> l.Prim(l.Not(uncover_get_expr(a, vars)))
    l.Prim(op: l.Or(a:, b:)) ->
      l.Prim(l.Or(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Plus(a:, b:)) ->
      l.Prim(l.Plus(uncover_get_expr(a, vars), uncover_get_expr(b, vars)))
    l.Prim(op: l.Void) -> l.Prim(l.Void)
    l.Prim(op: l.VectorLength(v:)) ->
      l.Prim(l.VectorLength(uncover_get_expr(v, vars)))
    l.Prim(op: l.VectorRef(v:, index:)) ->
      l.Prim(l.VectorRef(
        uncover_get_expr(v, vars),
        uncover_get_expr(index, vars),
      ))
    l.Prim(op: l.VectorSet(v:, index:, value:)) ->
      l.Prim(l.VectorSet(
        uncover_get_expr(v, vars),
        uncover_get_expr(index, vars),
        uncover_get_expr(value, vars),
      ))
  }
}

pub fn collect_set_bang(e: l.Expr) -> set.Set(String) {
  case e {
    l.GetBang(_) -> panic as "get! should not exist at this step"

    l.Var(_)
    | l.Int(_)
    | l.Bool(_)
    | l.Allocate(_, _)
    | l.Collect(_)
    | l.GlobalValue(_) -> set.new()
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

    l.HasType(value:, t: _) -> collect_set_bang(value)

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
    l.Prim(op: l.VectorLength(v:)) -> collect_set_bang(v)
    l.Prim(op: l.VectorRef(v:, index:)) ->
      set.union(collect_set_bang(v), collect_set_bang(index))
    l.Prim(op: l.VectorSet(v:, index:, value:)) ->
      v
      |> collect_set_bang()
      |> set.union(collect_set_bang(index))
      |> set.union(collect_set_bang(value))
  }
}
