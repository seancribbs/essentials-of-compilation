import eoc/langs/l_var
import gleam/dict
import gleam/int

// uniquify (shadowing of variables by making unique names)
//    Lvar -> Lvar
//
// (let ([x 32]) (+ let ([x 10]) x) x)
// (let ([x.1 32]) (+ let ([x.2 10]) x.2) x.1)
//
// (let ([x (let ([x 4]) (+ x 1))]) (+ x 2))
// (let ([x.2 (let ([x.1 4]) (+ x.1 1))]) (+ x.2 2))
pub fn uniquify(p: l_var.Program) -> l_var.Program {
  let #(expr, _) = uniquify_exp(p.body, dict.new(), 0)
  l_var.Program(expr)
}

fn uniquify_exp(
  e: l_var.Expr,
  env: dict.Dict(String, String),
  counter: Int,
) -> #(l_var.Expr, Int) {
  case e {
    l_var.Var(v) -> #(l_var.Var(get_var(env, v)), counter)
    l_var.Int(i) -> #(l_var.Int(i), counter)
    l_var.Let(v, e, body) -> {
      let #(e1, counter1) = uniquify_exp(e, env, counter)
      let counter_v = counter1 + 1
      let v1 = v <> "." <> int.to_string(counter_v)
      let #(body1, counter2) =
        uniquify_exp(body, dict.insert(env, v, v1), counter_v)
      #(l_var.Let(v1, e1, body1), counter2)
    }

    l_var.Prim(l_var.Plus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_var.Prim(l_var.Plus(a1, b1)), counter2)
    }

    l_var.Prim(l_var.Minus(a, b)) -> {
      let #(a1, counter1) = uniquify_exp(a, env, counter)
      let #(b1, counter2) = uniquify_exp(b, env, counter1)
      #(l_var.Prim(l_var.Minus(a1, b1)), counter2)
    }

    l_var.Prim(l_var.Negate(v)) -> {
      let #(a1, counter1) = uniquify_exp(v, env, counter)
      #(l_var.Prim(l_var.Negate(a1)), counter1)
    }

    l_var.Prim(l_var.Read) -> #(l_var.Prim(l_var.Read), counter)
  }
}

fn get_var(env: dict.Dict(String, a), name: String) -> a {
  case dict.get(env, name) {
    Error(_) -> panic as "referenced unknown variable"
    Ok(i) -> i
  }
}
