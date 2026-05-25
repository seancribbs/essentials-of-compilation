import eoc/langs/l_fun as lin
import eoc/langs/l_funref as lout
import gleam/dict
import gleam/list

pub fn reveal_functions(program: lin.Program) -> lout.Program {
  let assert lin.ProgramDefs(defs) = program
  let env =
    defs
    |> list.map(fn(def) {
      #(def.name, lout.FunRef(def.name, list.length(def.arguments)))
    })
    |> dict.from_list

  defs
  |> list.map(reveal_functions_def(_, env))
  |> lout.Program
}

fn reveal_functions_def(
  definition: lin.Definition,
  env: dict.Dict(String, lout.Expr),
) -> lout.Definition {
  let lin.Definition(name:, arguments:, return:, body:) = definition
  let env =
    list.fold(arguments, env, fn(env, arg) {
      dict.insert(env, arg.0, lout.Var(arg.0))
    })
  let body = reveal_functions_expr(body, env)
  lout.Definition(name:, arguments:, return:, body:)
}

fn reveal_functions_expr(
  expr: lin.Expr,
  env: dict.Dict(String, lout.Expr),
) -> lout.Expr {
  case expr {
    lin.Int(value:) -> lout.Int(value)
    lin.Bool(value:) -> lout.Bool(value)
    lin.Prim(op:) -> lout.Prim(reveal_functions_primop(op, env))
    lin.Var(name:) -> {
      case dict.get(env, name) {
        Error(_) -> panic as "undefined local variable"
        Ok(replacement) -> replacement
      }
    }
    lin.Let(var:, binding:, expr:) ->
      lout.Let(
        var:,
        binding: reveal_functions_expr(binding, env),
        expr: reveal_functions_expr(expr, dict.insert(env, var, lout.Var(var))),
      )
    lin.If(condition:, if_true:, if_false:) ->
      lout.If(
        reveal_functions_expr(condition, env),
        reveal_functions_expr(if_true, env),
        reveal_functions_expr(if_false, env),
      )
    lin.SetBang(var:, value:) ->
      lout.SetBang(var, reveal_functions_expr(value, env))
    lin.Begin(stmts:, result:) ->
      lout.Begin(
        list.map(stmts, reveal_functions_expr(_, env)),
        reveal_functions_expr(result, env),
      )
    lin.WhileLoop(condition:, body:) ->
      lout.WhileLoop(
        reveal_functions_expr(condition, env),
        reveal_functions_expr(body, env),
      )
    lin.HasType(value:, t:) ->
      lout.HasType(reveal_functions_expr(value, env), t)
    lin.Apply(function:, arguments:) ->
      lout.Apply(
        reveal_functions_expr(function, env),
        list.map(arguments, reveal_functions_expr(_, env)),
      )
  }
}

fn reveal_functions_primop(
  op: lin.PrimOp,
  env: dict.Dict(String, lout.Expr),
) -> lout.PrimOp {
  case op {
    lin.Read -> lout.Read
    lin.Void -> lout.Void
    lin.Negate(value:) -> lout.Negate(reveal_functions_expr(value, env))
    lin.Plus(a:, b:) ->
      lout.Plus(reveal_functions_expr(a, env), reveal_functions_expr(b, env))
    lin.Minus(a:, b:) ->
      lout.Minus(reveal_functions_expr(a, env), reveal_functions_expr(b, env))
    lin.Cmp(op:, a:, b:) ->
      lout.Cmp(op, reveal_functions_expr(a, env), reveal_functions_expr(b, env))
    lin.And(a:, b:) ->
      lout.And(reveal_functions_expr(a, env), reveal_functions_expr(b, env))
    lin.Or(a:, b:) ->
      lout.Or(reveal_functions_expr(a, env), reveal_functions_expr(b, env))
    lin.Not(a:) -> lout.Not(reveal_functions_expr(a, env))
    lin.Vector(fields:) ->
      lout.Vector(list.map(fields, reveal_functions_expr(_, env)))
    lin.VectorLength(v:) -> lout.VectorLength(reveal_functions_expr(v, env))
    lin.VectorRef(v:, index:) ->
      lout.VectorRef(
        reveal_functions_expr(v, env),
        reveal_functions_expr(index, env),
      )
    lin.VectorSet(v:, index:, value:) ->
      lout.VectorSet(
        reveal_functions_expr(v, env),
        reveal_functions_expr(index, env),
        reveal_functions_expr(value, env),
      )
  }
}
