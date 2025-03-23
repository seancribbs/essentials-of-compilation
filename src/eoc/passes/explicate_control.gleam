import eoc/langs/c_var
import eoc/langs/l_mon_var
import gleam/dict

// explicate_control (explicit execution order, graph with gotos)
//    LMonVar -> Cvar

// (let ([y (let ([x 20])
//            (+ x (let ([x 22]) x)))])
//   y)
//
// (let ([y.3 (let ([x.2 20])
//              (let ([x.1 22])
//                (+ x.2 x.1)))])
//  y.3)
//
// start:
//   x.2 = 20
//   x.1 = 22
//   y.3 = (+ x.2 x.1)
//   return y.3;

pub fn explicate_control(input: l_mon_var.Program) -> c_var.CProgram {
  let tail = explicate_tail(input.body)
  c_var.CProgram(dict.new(), dict.from_list([#("start", tail)]))
}

fn explicate_tail(input: l_mon_var.Expr) -> c_var.Tail {
  case input {
    l_mon_var.Atomic(l_mon_var.Var(v)) ->
      c_var.Return(c_var.Atom(c_var.Variable(v)))
    l_mon_var.Atomic(l_mon_var.Int(i)) -> c_var.Return(c_var.Atom(c_var.Int(i)))
    l_mon_var.Let(v, b, e) -> {
      let tail = explicate_tail(e)
      explicate_assign(b, v, tail)
    }
    l_mon_var.Prim(l_mon_var.Read) -> {
      c_var.Return(c_var.Prim(c_var.Read))
    }
    l_mon_var.Prim(l_mon_var.Negate(a)) -> {
      c_var.Return(c_var.Prim(c_var.Neg(convert_atm(a))))
    }
    l_mon_var.Prim(l_mon_var.Minus(a, b)) -> {
      c_var.Return(c_var.Prim(c_var.Minus(convert_atm(a), convert_atm(b))))
    }
    l_mon_var.Prim(l_mon_var.Plus(a, b)) -> {
      c_var.Return(c_var.Prim(c_var.Plus(convert_atm(a), convert_atm(b))))
    }
  }
}

fn explicate_assign(
  expr: l_mon_var.Expr,
  v: String,
  cont: c_var.Tail,
) -> c_var.Tail {
  case expr {
    // v := variable | int
    // ...cont
    l_mon_var.Atomic(a) ->
      c_var.Seq(c_var.Assign(v, c_var.Atom(convert_atm(a))), cont)
    // v := read()
    // ...cont
    l_mon_var.Prim(l_mon_var.Read) -> {
      c_var.Seq(c_var.Assign(v, c_var.Prim(c_var.Read)), cont)
    }
    // v := - a
    // ...cont
    l_mon_var.Prim(l_mon_var.Negate(a)) -> {
      c_var.Seq(c_var.Assign(v, c_var.Prim(c_var.Neg(convert_atm(a)))), cont)
    }
    // v := a - b
    // ...cont
    l_mon_var.Prim(l_mon_var.Minus(a, b)) -> {
      c_var.Seq(
        c_var.Assign(v, c_var.Prim(c_var.Minus(convert_atm(a), convert_atm(b)))),
        cont,
      )
    }
    // v := a + b
    // ...cont
    l_mon_var.Prim(l_mon_var.Plus(a, b)) -> {
      c_var.Seq(
        c_var.Assign(v, c_var.Prim(c_var.Plus(convert_atm(a), convert_atm(b)))),
        cont,
      )
    }
    // v1 := ...b
    // v := ...e
    // ...cont
    l_mon_var.Let(v1, b, e) -> {
      explicate_assign(b, v1, explicate_assign(e, v, cont))
    }
  }
}

fn convert_atm(input: l_mon_var.Atm) -> c_var.Atm {
  case input {
    l_mon_var.Int(i) -> c_var.Int(i)
    l_mon_var.Var(v) -> c_var.Variable(v)
  }
}
