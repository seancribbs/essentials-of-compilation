// remove_complex_operands (ensures atomic operands of primitive ops)
//    Lvar -> LMonVar

import gleam/dict
import gleam/int

import eoc/langs/l_mon_var
import eoc/langs/l_var

pub fn remove_complex_operands(input: l_var.Program) -> l_mon_var.Program {
  let #(rco, _) = rco_exp(input.body, 0)
  l_mon_var.Program(rco)
}

// (+ 42 (- 10))
//
// rco_atom: (- 10) => #(Var("tmp.1"), %{ "tmp.1" => Neg(Int(10)) })
//
// (let ([tmp.1 (- 10)])
//    (+ 42 tmp.1))

// (let ([a 42])
//    (let ([b a])
//      b))
// NOT:
// (let ([tmp.1 42])
//    (let ([a tmp.1])
//      (let ([tmp.2 a])
//        (let ([b tmp.2])
//          b))))

fn rco_atom(
  input: l_var.Expr,
  counter: Int,
) -> #(l_mon_var.Atm, dict.Dict(String, l_mon_var.Expr), Int) {
  case input {
    l_var.Int(i) -> #(l_mon_var.Int(i), dict.new(), counter)
    l_var.Var(v) -> #(l_mon_var.Var(v), dict.new(), counter)
    l_var.Let(v, b, e) -> {
      let #(binding, counter_b) = rco_exp(b, counter)
      let #(expr, counter_e) = rco_exp(e, counter_b)
      let #(var, new_counter) = new_var(counter_e)
      #(
        l_mon_var.Var(var),
        dict.from_list([#(var, l_mon_var.Let(v, binding, expr))]),
        new_counter,
      )
    }
    prim_expr -> {
      let #(expr, counter_e) = rco_exp(prim_expr, counter)
      let #(var, new_counter) = new_var(counter_e)
      #(l_mon_var.Var(var), dict.from_list([#(var, expr)]), new_counter)
    }
  }
}

fn rco_exp(input: l_var.Expr, counter: Int) -> #(l_mon_var.Expr, Int) {
  case input {
    l_var.Int(i) -> #(l_mon_var.Atomic(l_mon_var.Int(i)), counter)
    l_var.Var(v) -> #(l_mon_var.Atomic(l_mon_var.Var(v)), counter)
    l_var.Let(v, b, e) -> {
      let #(binding, new_counter) = rco_exp(b, counter)
      let #(expr, new_counter1) = rco_exp(e, new_counter)
      #(l_mon_var.Let(v, binding, expr), new_counter1)
    }
    l_var.Prim(l_var.Read) -> #(l_mon_var.Prim(l_mon_var.Read), counter)

    l_var.Prim(l_var.Negate(e)) -> {
      let #(atm, bindings, new_counter) = rco_atom(e, counter)
      let new_expr =
        dict.fold(
          bindings,
          l_mon_var.Prim(l_mon_var.Negate(atm)),
          fn(exp, variable, binding) { l_mon_var.Let(variable, binding, exp) },
        )
      #(new_expr, new_counter)
    }
    l_var.Prim(l_var.Minus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> dict.merge(bindings_b)
        |> dict.fold(
          l_mon_var.Prim(l_mon_var.Minus(atm_a, atm_b)),
          fn(exp, variable, binding) { l_mon_var.Let(variable, binding, exp) },
        )

      #(new_expr, counter_b)
    }
    l_var.Prim(l_var.Plus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> dict.merge(bindings_b)
        |> dict.fold(
          l_mon_var.Prim(l_mon_var.Plus(atm_a, atm_b)),
          fn(exp, variable, binding) { l_mon_var.Let(variable, binding, exp) },
        )

      #(new_expr, counter_b)
    }
  }
}

fn new_var(counter: Int) -> #(String, Int) {
  let new_count = counter + 1
  let name = "tmp." <> int.to_string(new_count)
  #(name, new_count)
}
