import eoc/runtime
import gleam/dict

pub type PrimOp {
  Read
  Negate(value: Expr)
  Plus(a: Expr, b: Expr)
  Minus(a: Expr, b: Expr)
}

pub type Expr {
  Int(value: Int)
  Prim(op: PrimOp)
  Var(name: String)
  Let(var: String, binding: Expr, expr: Expr)
}

pub type Program {
  Program(body: Expr)
}

type Env =
  dict.Dict(String, Int)

pub fn interpret(p: Program) -> Int {
  interpret_exp(p.body, dict.new())
}

fn interpret_exp(e: Expr, env: Env) -> Int {
  case e {
    Int(value) -> value
    Prim(op) -> interpret_op(op, env)
    Var(name) -> get_var(env, name)
    Let(var, binding, expr) -> {
      let result = interpret_exp(binding, env)
      let new_env = dict.insert(env, var, result)
      interpret_exp(expr, new_env)
    }
  }
}

fn interpret_op(op: PrimOp, env: Env) -> Int {
  case op {
    Minus(a, b) -> interpret_exp(a, env) - interpret_exp(b, env)
    Negate(v) -> -interpret_exp(v, env)
    Plus(a, b) -> interpret_exp(a, env) + interpret_exp(b, env)
    Read -> runtime.read_int()
  }
}

fn get_var(env: Env, name: String) -> Int {
  case dict.get(env, name) {
    Error(_) -> panic as "referenced unknown variable"
    Ok(i) -> i
  }
}
// pub fn partial(p: Program) -> Program {
//   Program(partial_exp(p.body))
// }

// fn partial_exp(e: Expr) -> Expr {
//   case e {
//     Int(i) -> Int(i)
//     Prim(Read) -> Prim(Read)
//     Prim(Negate(e1)) -> partial_neg(partial_exp(e1))
//     Prim(Plus(e1, e2)) -> partial_add(partial_exp(e1), partial_exp(e2))
//     Prim(Minus(e1, e2)) -> partial_sub(partial_exp(e1), partial_exp(e2))
//   }
// }

// fn partial_neg(e: Expr) -> Expr {
//   case e {
//     Int(v) -> Int(-v)
//     e1 -> Prim(Negate(e1))
//   }
// }

// fn partial_add(e1: Expr, e2: Expr) -> Expr {
//   case e1, e2 {
//     Int(a), Int(b) -> Int(a + b)
//     _, _ -> Prim(Plus(e1, e2))
//   }
// }

// fn partial_sub(e1: Expr, e2: Expr) -> Expr {
//   case e1, e2 {
//     Int(a), Int(b) -> Int(a - b)
//     _, _ -> Prim(Minus(e1, e2))
//   }
// }
