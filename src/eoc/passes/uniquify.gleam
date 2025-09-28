import eoc/langs/l_tup as l
import gleam/dict
import gleam/int
import gleam/list
import gleam/pair

// uniquify (shadowing of variables by making unique names)
//    Lwhile -> Lwhile
//
// (let ([x 32]) (+ (let ([x 10]) x) x)
// (let ([x.1 32]) (+ (let ([x.2 10]) x.2) x.1)
//
// (let ([x (let ([x 4]) (+ x 1))]) (+ x 2))
// (let ([x.2 (let ([x.1 4]) (+ x.1 1))]) (+ x.2 2))
pub fn uniquify(p: l.Program) -> l.Program {
  let #(expr, _) = uniquify_exp(p.body, dict.new(), 0)
  l.Program(expr)
}

fn uniquify_exp(
  e: l.Expr,
  env: dict.Dict(String, String),
  counter: Int,
) -> #(l.Expr, Int) {
  case e {
    l.Var(v) -> #(l.Var(get_var(env, v)), counter)
    l.Int(i) -> #(l.Int(i), counter)
    l.Bool(b) -> #(l.Bool(b), counter)

    l.Let(v, e, body) -> {
      let #(e1, counter1) = uniquify_exp(e, env, counter)
      let counter_v = counter1 + 1
      let v1 = v <> "." <> int.to_string(counter_v)
      let #(body1, counter2) =
        uniquify_exp(body, dict.insert(env, v, v1), counter_v)
      #(l.Let(v1, e1, body1), counter2)
    }

    l.If(cond, if_true, if_false) -> {
      let #(c1, counter1) = uniquify_exp(cond, env, counter)
      let #(t1, counter2) = uniquify_exp(if_true, env, counter1)
      let #(f1, counter3) = uniquify_exp(if_false, env, counter2)
      #(l.If(c1, t1, f1), counter3)
    }

    l.Prim(l.Plus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l.Prim(l.Plus(a1, b1)), counter2)
    }

    l.Prim(l.Minus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l.Prim(l.Minus(a1, b1)), counter2)
    }

    l.Prim(l.Negate(v)) -> {
      let #(a1, counter1) = uniquify_exp(v, env, counter)
      #(l.Prim(l.Negate(a1)), counter1)
    }

    l.Prim(l.Read) -> #(l.Prim(l.Read), counter)

    l.Prim(l.And(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l.Prim(l.And(a1, b1)), counter2)
    }

    l.Prim(l.Or(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l.Prim(l.Or(a1, b1)), counter2)
    }

    l.Prim(l.Cmp(op, a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l.Prim(l.Cmp(op, a1, b1)), counter2)
    }

    l.Prim(l.Not(a)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      #(l.Prim(l.Not(a1)), counter1)
    }

    l.Prim(op: l.Void) -> #(l.Prim(l.Void), counter)

    l.Prim(op: l.Vector(fields:)) -> {
      let #(counter1, fields1) =
        list.map_fold(fields, counter, fn(c, stmt) {
          pair.swap(uniquify_exp(stmt, env, c))
        })
      #(l.Prim(l.Vector(fields1)), counter1)
    }

    l.Prim(op: l.VectorLength(v:)) -> {
      let #(v1, counter1) = uniquify_exp(v, env, counter)
      #(l.Prim(l.VectorLength(v1)), counter1)
    }

    l.Prim(op: l.VectorRef(v:, index:)) -> {
      let #(v1, counter1) = uniquify_exp(v, env, counter)
      let #(index1, counter2) = uniquify_exp(index, env, counter1)
      #(l.Prim(l.VectorRef(v1, index1)), counter2)
    }

    l.Prim(op: l.VectorSet(v:, index:, value:)) -> {
      let #(v1, counter1) = uniquify_exp(v, env, counter)
      let #(index1, counter2) = uniquify_exp(index, env, counter1)
      let #(value1, counter3) = uniquify_exp(value, env, counter2)
      #(l.Prim(l.VectorSet(v1, index1, value1)), counter3)
    }

    l.SetBang(var:, value:) -> {
      let #(value1, counter1) = uniquify_exp(value, env, counter)
      #(l.SetBang(get_var(env, var), value: value1), counter1)
    }

    l.Begin(stmts:, result:) -> {
      let #(counter1, stmts1) =
        list.map_fold(stmts, counter, fn(c, stmt) {
          pair.swap(uniquify_exp(stmt, env, c))
        })
      let #(result1, counter2) = uniquify_exp(result, env, counter1)
      #(l.Begin(stmts1, result1), counter2)
    }

    l.WhileLoop(condition:, body:) -> {
      let #(condition1, counter1) = uniquify_exp(condition, env, counter)
      let #(body1, counter2) = uniquify_exp(body, env, counter1)
      #(l.WhileLoop(condition1, body1), counter2)
    }

    l.HasType(value:, t:) -> {
      let #(value1, counter1) = uniquify_exp(value, env, counter)
      #(l.HasType(value: value1, t:), counter1)
    }
  }
}

fn get_var(env: dict.Dict(String, a), name: String) -> a {
  case dict.get(env, name) {
    Error(_) -> panic as "referenced unknown variable"
    Ok(i) -> i
  }
}
