import eoc/langs/l_if
import gleam/dict
import gleam/int

// uniquify (shadowing of variables by making unique names)
//    Lvar -> Lvar
//
// (let ([x 32]) (+ (let ([x 10]) x) x)
// (let ([x.1 32]) (+ (let ([x.2 10]) x.2) x.1)
//
// (let ([x (let ([x 4]) (+ x 1))]) (+ x 2))
// (let ([x.2 (let ([x.1 4]) (+ x.1 1))]) (+ x.2 2))
pub fn uniquify(p: l_if.Program) -> l_if.Program {
  let #(expr, _) = uniquify_exp(p.body, dict.new(), 0)
  l_if.Program(expr)
}

fn uniquify_exp(
  e: l_if.Expr,
  env: dict.Dict(String, String),
  counter: Int,
) -> #(l_if.Expr, Int) {
  case e {
    l_if.Var(v) -> #(l_if.Var(get_var(env, v)), counter)
    l_if.Int(i) -> #(l_if.Int(i), counter)
    l_if.Bool(b) -> #(l_if.Bool(b), counter)

    l_if.Let(v, e, body) -> {
      let #(e1, counter1) = uniquify_exp(e, env, counter)
      let counter_v = counter1 + 1
      let v1 = v <> "." <> int.to_string(counter_v)
      let #(body1, counter2) =
        uniquify_exp(body, dict.insert(env, v, v1), counter_v)
      #(l_if.Let(v1, e1, body1), counter2)
    }

    l_if.If(cond, if_true, if_false) -> {
      let #(c1, counter1) = uniquify_exp(cond, env, counter)
      let #(t1, counter2) = uniquify_exp(if_true, env, counter1)
      let #(f1, counter3) = uniquify_exp(if_false, env, counter2)
      #(l_if.If(c1, t1, f1), counter3)
    }

    l_if.Prim(l_if.Plus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_if.Prim(l_if.Plus(a1, b1)), counter2)
    }

    l_if.Prim(l_if.Minus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_if.Prim(l_if.Minus(a1, b1)), counter2)
    }

    l_if.Prim(l_if.Negate(v)) -> {
      let #(a1, counter1) = uniquify_exp(v, env, counter)
      #(l_if.Prim(l_if.Negate(a1)), counter1)
    }

    l_if.Prim(l_if.Read) -> #(l_if.Prim(l_if.Read), counter)

    l_if.Prim(l_if.And(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_if.Prim(l_if.And(a1, b1)), counter2)
    }

    l_if.Prim(l_if.Or(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_if.Prim(l_if.Or(a1, b1)), counter2)
    }

    l_if.Prim(l_if.Cmp(op, a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_if.Prim(l_if.Cmp(op, a1, b1)), counter2)
    }

    l_if.Prim(l_if.Not(a)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      #(l_if.Prim(l_if.Not(a1)), counter1)
    }
  }
}

fn get_var(env: dict.Dict(String, a), name: String) -> a {
  case dict.get(env, name) {
    Error(_) -> panic as "referenced unknown variable"
    Ok(i) -> i
  }
}
