// remove_complex_operands (ensures atomic operands of primitive ops)
//    Lif -> LMonIf

import gleam/int
import gleam/list

import eoc/langs/l_if
import eoc/langs/l_mon_if

pub fn remove_complex_operands(input: l_if.Program) -> l_mon_if.Program {
  let #(rco, _) = rco_exp(input.body, 0)
  l_mon_if.Program(rco)
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
  input: l_if.Expr,
  counter: Int,
) -> #(l_mon_if.Atm, List(#(String, l_mon_if.Expr)), Int) {
  case input {
    l_if.Int(i) -> #(l_mon_if.Int(i), [], counter)
    l_if.Bool(b) -> #(l_mon_if.Bool(b), [], counter)
    l_if.Var(v) -> #(l_mon_if.Var(v), [], counter)
    l_if.Let(v, b, e) -> {
      let #(binding, counter_b) = rco_exp(b, counter)
      let #(expr, counter_e) = rco_exp(e, counter_b)
      let #(var, new_counter) = new_var(counter_e)
      #(
        l_mon_if.Var(var),
        [#(var, l_mon_if.Let(v, binding, expr))],
        new_counter,
      )
    }
    l_if.If(c, t, e) -> {
      let #(c1, counter1) = rco_exp(c, counter)
      let #(t1, counter2) = rco_exp(t, counter1)
      let #(e1, counter3) = rco_exp(e, counter2)
      let #(var, new_counter) = new_var(counter3)
      #(l_mon_if.Var(var), [#(var, l_mon_if.If(c1, t1, e1))], new_counter)
    }
    l_if.Prim(op: l_if.And(_, _)) | l_if.Prim(op: l_if.Or(_, _)) -> {
      panic as "shrink pass was not run before remove_complex_operands"
    }
    l_if.Prim(_) -> {
      let #(expr, counter_e) = rco_exp(input, counter)
      let #(var, new_counter) = new_var(counter_e)
      #(l_mon_if.Var(var), [#(var, expr)], new_counter)
    }
  }
}

fn rco_exp(input: l_if.Expr, counter: Int) -> #(l_mon_if.Expr, Int) {
  case input {
    l_if.Int(i) -> #(l_mon_if.Atomic(l_mon_if.Int(i)), counter)
    l_if.Var(v) -> #(l_mon_if.Atomic(l_mon_if.Var(v)), counter)
    l_if.Bool(value:) -> #(l_mon_if.Atomic(l_mon_if.Bool(value)), counter)

    l_if.Let(v, b, e) -> {
      let #(binding, new_counter) = rco_exp(b, counter)
      let #(expr, new_counter1) = rco_exp(e, new_counter)
      #(l_mon_if.Let(v, binding, expr), new_counter1)
    }

    l_if.If(condition:, if_true:, if_false:) -> {
      let #(c1, counter1) = rco_exp(condition, counter)
      let #(t1, counter2) = rco_exp(if_true, counter1)
      let #(f1, counter3) = rco_exp(if_false, counter2)
      #(l_mon_if.If(c1, t1, f1), counter3)
    }

    l_if.Prim(l_if.Read) -> #(l_mon_if.Prim(l_mon_if.Read), counter)

    l_if.Prim(l_if.Negate(e)) -> {
      let #(atm, bindings, new_counter) = rco_atom(e, counter)
      let new_expr =
        list.fold(bindings, l_mon_if.Prim(l_mon_if.Negate(atm)), fn(exp, pair) {
          l_mon_if.Let(pair.0, pair.1, exp)
        })
      #(new_expr, new_counter)
    }

    l_if.Prim(l_if.Minus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(
          l_mon_if.Prim(l_mon_if.Minus(atm_a, atm_b)),
          fn(exp, pair) { l_mon_if.Let(pair.0, pair.1, exp) },
        )

      #(new_expr, counter_b)
    }

    l_if.Prim(l_if.Plus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(
          l_mon_if.Prim(l_mon_if.Plus(atm_a, atm_b)),
          fn(exp, pair) { l_mon_if.Let(pair.0, pair.1, exp) },
        )

      #(new_expr, counter_b)
    }
    l_if.Prim(op: l_if.Cmp(op:, a:, b:)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(
          l_mon_if.Prim(l_mon_if.Cmp(op, atm_a, atm_b)),
          fn(exp, pair) { l_mon_if.Let(pair.0, pair.1, exp) },
        )

      #(new_expr, counter_b)
    }

    l_if.Prim(op: l_if.Not(a:)) -> {
      let #(atm, bindings, new_counter) = rco_atom(a, counter)
      let new_expr =
        list.fold(bindings, l_mon_if.Prim(l_mon_if.Not(atm)), fn(exp, pair) {
          l_mon_if.Let(pair.0, pair.1, exp)
        })
      #(new_expr, new_counter)
    }

    l_if.Prim(op: l_if.And(_, _)) | l_if.Prim(op: l_if.Or(_, _)) -> {
      panic as "shrink pass was not run before remove_complex_operands"
    }
  }
}

fn new_var(counter: Int) -> #(String, Int) {
  let new_count = counter + 1
  let name = "tmp." <> int.to_string(new_count)
  #(name, new_count)
}
