import eoc/langs/l_fun.{FunT, VectorT}
import eoc/langs/l_funref as l
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair

pub fn limit_functions(p: l.Program) -> l.Program {
  p.defs
  |> list.map(limit_function)
  |> l.Program
}

fn limit_function(definition: l.Definition) -> l.Definition {
  // Transform definition if it has more than 6 arguments
  let #(arguments, indices) = case list.split(definition.arguments, 6) {
    #(args, []) -> #(args, dict.new())
    #([a, b, c, d, e, f], extra) -> {
      let tup = #("tup", VectorT(list.map([f, ..extra], pair.second)))
      let indices = list.index_map([f, ..extra], fn(arg, idx) { #(arg.0, idx) })
      #([a, b, c, d, e, tup], dict.from_list(indices))
    }
    _ -> panic as "list.split in limit_function"
  }
  // Transform all function applications in the body and extended arguments
  let body = limit_function_expr(definition.body, indices)

  l.Definition(..definition, arguments:, body:)
}

fn limit_function_expr(
  expr: l.Expr,
  indices: dict.Dict(String, Int),
) -> l.Expr {
  case expr {
    l.Var(name:) ->
      case dict.get(indices, name) {
        Ok(i) -> l.Prim(l.VectorRef(l.Var("tup"), l.Int(i)))
        _ -> l.Var(name:)
      }
    l.FunRef(name:, arity:) -> l.FunRef(name:, arity: int.min(arity, 6))
    l.Apply(function: l.HasType(function, FunT(arg_types, _)), arguments:) -> {
      let function = limit_function_expr(function, indices)
      let arguments = case list.split(arguments, 6) {
        #(_, []) -> arguments
        #([a, b, c, d, e, f], rest) -> {
          let #(_, trailing_arg_types) = list.split(arg_types, 5)
          let vec =
            l.HasType(
              l.Prim(l.Vector([f, ..rest])),
              VectorT(trailing_arg_types),
            )
          [a, b, c, d, e, vec]
        }
        _ -> panic as "list.split in limit_function_body"
      }
      l.Apply(function:, arguments:)
    }
    l.Apply(function: _, arguments: _) -> panic as "untyped function call"
    l.Int(_) | l.Bool(_) -> expr
    l.Prim(op:) -> l.Prim(limit_function_op(op, indices))
    l.Let(var:, binding:, expr:) ->
      l.Let(
        var:,
        binding: limit_function_expr(binding, indices),
        expr: limit_function_expr(expr, indices),
      )
    l.If(condition:, if_true:, if_false:) ->
      l.If(
        condition: limit_function_expr(condition, indices),
        if_true: limit_function_expr(if_true, indices),
        if_false: limit_function_expr(if_false, indices),
      )
    l.SetBang(var:, value:) ->
      l.SetBang(var:, value: limit_function_expr(value, indices))
    l.Begin(stmts:, result:) ->
      l.Begin(
        stmts: list.map(stmts, limit_function_expr(_, indices)),
        result: limit_function_expr(result, indices),
      )
    l.WhileLoop(condition:, body:) ->
      l.WhileLoop(
        condition: limit_function_expr(condition, indices),
        body: limit_function_expr(body, indices),
      )
    l.HasType(value:, t:) ->
      l.HasType(value: limit_function_expr(value, indices), t:)
  }
}

fn limit_function_op(
  op: l.PrimOp,
  indices: dict.Dict(String, Int),
) -> l.PrimOp {
  case op {
    l.Read -> l.Read
    l.Void -> l.Void
    l.Negate(value:) -> l.Negate(limit_function_expr(value, indices))
    l.Plus(a:, b:) ->
      l.Plus(
        a: limit_function_expr(a, indices),
        b: limit_function_expr(b, indices),
      )
    l.Minus(a:, b:) ->
      l.Minus(
        a: limit_function_expr(a, indices),
        b: limit_function_expr(b, indices),
      )
    l.Cmp(op:, a:, b:) ->
      l.Cmp(
        op:,
        a: limit_function_expr(a, indices),
        b: limit_function_expr(b, indices),
      )
    l.And(a:, b:) ->
      l.And(
        a: limit_function_expr(a, indices),
        b: limit_function_expr(b, indices),
      )
    l.Or(a:, b:) ->
      l.Or(
        a: limit_function_expr(a, indices),
        b: limit_function_expr(b, indices),
      )
    l.Not(a:) -> l.Not(a: limit_function_expr(a, indices))
    l.Vector(fields:) ->
      l.Vector(list.map(fields, limit_function_expr(_, indices)))
    l.VectorLength(v:) -> l.VectorLength(limit_function_expr(v, indices))
    l.VectorRef(v:, index:) ->
      l.VectorRef(
        v: limit_function_expr(v, indices),
        index: limit_function_expr(index, indices),
      )
    l.VectorSet(v:, index:, value:) ->
      l.VectorSet(
        v: limit_function_expr(v, indices),
        index: limit_function_expr(index, indices),
        value: limit_function_expr(value, indices),
      )
  }
}
