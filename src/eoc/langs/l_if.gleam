import gleam/dict
import gleam/erlang
import gleam/int
import gleam/result
import gleam/string

pub type Type {
  Integer
  Boolean
}

pub type Cmp {
  Eq
  Lt
  Lte
  Gt
  Gte
}

pub type PrimOp {
  Read
  Negate(value: Expr)
  Plus(a: Expr, b: Expr)
  Minus(a: Expr, b: Expr)
  Cmp(op: Cmp, a: Expr, b: Expr)
  And(a: Expr, b: Expr)
  Or(a: Expr, b: Expr)
  Not(a: Expr)
}

pub type Expr {
  Int(value: Int)
  Bool(value: Bool)
  Prim(op: PrimOp)
  Var(name: String)
  Let(var: String, binding: Expr, expr: Expr)
  If(condition: Expr, if_true: Expr, if_false: Expr)
}

pub type Program {
  Program(body: Expr)
}

type Env =
  dict.Dict(String, IValue)

pub type IValue {
  IntValue(v: Int)
  BoolValue(v: Bool)
}

pub fn interpret(p: Program) -> IValue {
  interpret_exp(p.body, dict.new())
}

fn interpret_exp(e: Expr, env: Env) -> IValue {
  case e {
    Int(value) -> IntValue(value)
    Prim(op) -> interpret_op(op, env)
    Var(name) -> get_var(env, name)
    Let(var, binding, expr) -> {
      let result = interpret_exp(binding, env)
      let new_env = dict.insert(env, var, result)
      interpret_exp(expr, new_env)
    }
    Bool(value) -> BoolValue(value)
    If(c, t, e) -> {
      case interpret_exp(c, env) {
        BoolValue(True) -> interpret_exp(t, env)
        BoolValue(False) -> interpret_exp(e, env)
        IntValue(_) -> panic as "invalid boolean expression"
      }
    }
  }
}

fn interpret_op(op: PrimOp, env: Env) -> IValue {
  case op {
    Negate(v) -> {
      let assert IntValue(i) = interpret_exp(v, env)
      IntValue(-i)
    }
    Minus(a, b) -> {
      let assert IntValue(av) = interpret_exp(a, env)
      let assert IntValue(bv) = interpret_exp(b, env)
      IntValue(av - bv)
    }
    Plus(a, b) -> {
      let assert IntValue(av) = interpret_exp(a, env)
      let assert IntValue(bv) = interpret_exp(b, env)
      IntValue(av + bv)
    }
    Read -> IntValue(read_int())
    And(a, b) -> {
      case interpret_exp(a, env) {
        BoolValue(True) -> {
          let assert BoolValue(bv) = interpret_exp(b, env)
          BoolValue(bv)
        }
        BoolValue(False) -> {
          BoolValue(False)
        }
        _ -> panic as "integer expression not valid in `and`"
      }
    }
    Or(a, b) -> {
      case interpret_exp(a, env) {
        BoolValue(True) -> BoolValue(True)
        BoolValue(False) -> {
          let assert BoolValue(bv) = interpret_exp(b, env)
          BoolValue(bv)
        }
        _ -> panic as "integer expression not valid in `or`"
      }
    }
    Not(e) -> {
      let assert BoolValue(v) = interpret_exp(e, env)
      BoolValue(!v)
    }
    Cmp(Eq, a, b) -> {
      case interpret_exp(a, env), interpret_exp(b, env) {
        IntValue(av), IntValue(bv) -> BoolValue(av == bv)
        BoolValue(av), BoolValue(bv) -> BoolValue(av == bv)
        _, _ ->
          panic as "integer expressions are not equal to boolean expressions"
      }
    }
    Cmp(op, a, b) -> {
      let assert IntValue(av) = interpret_exp(a, env)
      let assert IntValue(bv) = interpret_exp(b, env)
      case op {
        Gt -> BoolValue(av > bv)
        Gte -> BoolValue(av >= bv)
        Lt -> BoolValue(av < bv)
        Lte -> BoolValue(av <= bv)
        Eq -> panic as "unreachable branch"
      }
    }
  }
}

fn get_var(env: Env, name: String) -> IValue {
  case dict.get(env, name) {
    Error(_) -> panic as "referenced unknown variable"
    Ok(i) -> i
  }
}

fn read_int() -> Int {
  let result = {
    erlang.get_line("> ")
    |> result.map_error(fn(_) { Nil })
    |> result.try(fn(line) { line |> string.trim() |> int.parse() })
  }

  case result {
    Error(_) -> panic as "could not read an int from stdin"
    Ok(i) -> i
  }
}
