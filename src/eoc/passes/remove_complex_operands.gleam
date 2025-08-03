// remove_complex_operands (ensures atomic operands of primitive ops)
//    Lwhile -> LMonWhile

import gleam/int
import gleam/list
import gleam/pair

import eoc/langs/l_mon_while as l_mon
import eoc/langs/l_while_get as l

pub fn remove_complex_operands(input: l.Program) -> l_mon.Program {
  let #(rco, _) = rco_exp(input.body, 0)
  l_mon.Program(rco)
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
  input: l.Expr,
  counter: Int,
) -> #(l_mon.Atm, List(#(String, l_mon.Expr)), Int) {
  case input {
    l.Int(i) -> #(l_mon.Int(i), [], counter)
    l.Bool(b) -> #(l_mon.Bool(b), [], counter)
    l.Var(v) -> #(l_mon.Var(v), [], counter)
    l.Let(v, b, e) -> {
      let #(binding, counter_b) = rco_exp(b, counter)
      let #(expr, counter_e) = rco_exp(e, counter_b)
      let #(var, new_counter) = new_var(counter_e)
      #(l_mon.Var(var), [#(var, l_mon.Let(v, binding, expr))], new_counter)
    }
    l.If(c, t, e) -> {
      let #(c1, counter1) = rco_exp(c, counter)
      let #(t1, counter2) = rco_exp(t, counter1)
      let #(e1, counter3) = rco_exp(e, counter2)
      let #(var, new_counter) = new_var(counter3)
      #(l_mon.Var(var), [#(var, l_mon.If(c1, t1, e1))], new_counter)
    }
    l.Prim(op: l.And(_, _)) | l.Prim(op: l.Or(_, _)) -> {
      panic as "shrink pass was not run before remove_complex_operands"
    }
    l.Prim(l.Void) -> #(l_mon.Void, [], counter)
    l.Prim(_) -> {
      let #(expr, counter_e) = rco_exp(input, counter)
      let #(var, new_counter) = new_var(counter_e)
      #(l_mon.Var(var), [#(var, expr)], new_counter)
    }
    l.Begin(stmts:, result:) -> {
      let #(counter1, stmts1) =
        list.map_fold(stmts, counter, fn(c, s) { pair.swap(rco_exp(s, c)) })
      let #(result1, counter2) = rco_exp(result, counter1)
      let #(var, new_counter) = new_var(counter2)
      #(l_mon.Var(var), [#(var, l_mon.Begin(stmts1, result1))], new_counter)
    }
    l.GetBang(var:) -> {
      let #(new_var, new_counter) = new_var(counter)
      #(l_mon.Var(new_var), [#(new_var, l_mon.GetBang(var))], new_counter)
    }
    l.SetBang(var:, value:) -> {
      let #(value1, counter1) = rco_exp(value, counter)
      let #(new_var, new_counter) = new_var(counter1)
      #(l_mon.Void, [#(new_var, l_mon.SetBang(var, value1))], new_counter)
    }
    l.WhileLoop(condition:, body:) -> {
      let #(condition1, counter1) = rco_exp(condition, counter)
      let #(body1, counter2) = rco_exp(body, counter1)
      let #(new_var, new_counter) = new_var(counter2)
      #(
        l_mon.Void,
        [#(new_var, l_mon.WhileLoop(condition1, body1))],
        new_counter,
      )
    }
  }
}

fn rco_exp(input: l.Expr, counter: Int) -> #(l_mon.Expr, Int) {
  case input {
    l.Int(i) -> #(l_mon.Atomic(l_mon.Int(i)), counter)
    l.Var(v) -> #(l_mon.Atomic(l_mon.Var(v)), counter)
    l.Bool(value:) -> #(l_mon.Atomic(l_mon.Bool(value)), counter)

    l.Let(v, b, e) -> {
      let #(binding, new_counter) = rco_exp(b, counter)
      let #(expr, new_counter1) = rco_exp(e, new_counter)
      #(l_mon.Let(v, binding, expr), new_counter1)
    }

    l.If(condition:, if_true:, if_false:) -> {
      let #(c1, counter1) = rco_exp(condition, counter)
      let #(t1, counter2) = rco_exp(if_true, counter1)
      let #(f1, counter3) = rco_exp(if_false, counter2)
      #(l_mon.If(c1, t1, f1), counter3)
    }

    l.Prim(l.Void) -> #(l_mon.Atomic(l_mon.Void), counter)

    l.Prim(l.Read) -> #(l_mon.Prim(l_mon.Read), counter)

    l.Prim(l.Negate(e)) -> {
      let #(atm, bindings, new_counter) = rco_atom(e, counter)
      let new_expr =
        list.fold(bindings, l_mon.Prim(l_mon.Negate(atm)), fn(exp, pair) {
          l_mon.Let(pair.0, pair.1, exp)
        })
      #(new_expr, new_counter)
    }

    l.Prim(l.Minus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(l_mon.Prim(l_mon.Minus(atm_a, atm_b)), fn(exp, pair) {
          l_mon.Let(pair.0, pair.1, exp)
        })

      #(new_expr, counter_b)
    }

    l.Prim(l.Plus(a, b)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(l_mon.Prim(l_mon.Plus(atm_a, atm_b)), fn(exp, pair) {
          l_mon.Let(pair.0, pair.1, exp)
        })

      #(new_expr, counter_b)
    }
    l.Prim(op: l.Cmp(op:, a:, b:)) -> {
      let #(atm_a, bindings_a, counter_a) = rco_atom(a, counter)
      let #(atm_b, bindings_b, counter_b) = rco_atom(b, counter_a)
      let new_expr =
        bindings_a
        |> list.append(bindings_b)
        |> list.fold_right(
          l_mon.Prim(l_mon.Cmp(op, atm_a, atm_b)),
          fn(exp, pair) { l_mon.Let(pair.0, pair.1, exp) },
        )

      #(new_expr, counter_b)
    }

    l.Prim(op: l.Not(a:)) -> {
      let #(atm, bindings, new_counter) = rco_atom(a, counter)
      let new_expr =
        list.fold(bindings, l_mon.Prim(l_mon.Not(atm)), fn(exp, pair) {
          l_mon.Let(pair.0, pair.1, exp)
        })
      #(new_expr, new_counter)
    }

    l.Prim(op: l.And(_, _)) | l.Prim(op: l.Or(_, _)) -> {
      panic as "shrink pass was not run before remove_complex_operands"
    }

    l.Begin(stmts:, result:) -> {
      let #(counter1, stmts1) =
        list.map_fold(stmts, counter, fn(c, s) { pair.swap(rco_exp(s, c)) })
      let #(result1, counter2) = rco_exp(result, counter1)
      #(l_mon.Begin(stmts1, result1), counter2)
    }
    l.GetBang(var:) -> #(l_mon.GetBang(var), counter)
    l.SetBang(var:, value:) -> {
      let #(value1, counter1) = rco_exp(value, counter)
      #(l_mon.SetBang(var, value1), counter1)
    }

    l.WhileLoop(condition:, body:) -> {
      let #(condition1, counter1) = rco_exp(condition, counter)
      let #(body1, counter2) = rco_exp(body, counter1)
      #(l_mon.WhileLoop(condition1, body1), counter2)
    }
  }
}

fn new_var(counter: Int) -> #(String, Int) {
  let new_count = counter + 1
  let name = "tmp." <> int.to_string(new_count)
  #(name, new_count)
}
