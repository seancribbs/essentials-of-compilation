import eoc/runtime
import gleam/dict
import gleam/result

pub type Type {
  Integer
  Boolean
}

pub type TypeError {
  TypeError(expected: Type, actual: Type, expression: Expr)
  UnboundVariable(name: String)
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
    Read -> IntValue(runtime.read_int())
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

type TypeEnv =
  dict.Dict(String, Type)

pub fn type_check_program(p: Program) -> Result(Program, TypeError) {
  case type_check_exp(p.body, dict.new()) {
    Ok(#(expr, Integer)) -> Ok(Program(expr))
    Ok(#(expr, Boolean)) -> Error(TypeError(Integer, Boolean, expr))
    Error(err) -> Error(err)
  }
}

pub fn type_check_exp(e: Expr, env: TypeEnv) -> Result(#(Expr, Type), TypeError) {
  case e {
    Bool(_) -> Ok(#(e, Boolean))
    Int(_) -> Ok(#(e, Integer))
    Var(v) -> {
      case dict.get(env, v) {
        Ok(t) -> Ok(#(e, t))
        Error(_) -> Error(UnboundVariable(v))
      }
    }
    Prim(p) -> {
      use #(op, t) <- result.map(type_check_op(p, env))
      #(Prim(op), t)
    }
    Let(x, e, body) -> {
      use #(e1, t) <- result.try(type_check_exp(e, env))
      use #(body1, tb) <- result.map(type_check_exp(
        body,
        dict.insert(env, x, t),
      ))
      #(Let(x, e1, body1), tb)
    }
    If(cond, thn, els) -> {
      use #(c1, tc) <- result.try(type_check_exp(cond, env))
      use _ <- result.try(check_type_equal(Boolean, tc, c1))
      use #(t1, tt) <- result.try(type_check_exp(thn, env))
      use #(e1, te) <- result.try(type_check_exp(els, env))
      use _ <- result.map(check_type_equal(tt, te, e1))
      #(If(c1, t1, e1), te)
    }
  }
}

pub fn type_check_op(
  p: PrimOp,
  env: TypeEnv,
) -> Result(#(PrimOp, Type), TypeError) {
  case p {
    Read -> Ok(#(Read, Integer))
    Negate(e) -> {
      use #(e1, te) <- result.try(type_check_exp(e, env))
      use _ <- result.map(check_type_equal(Boolean, te, e1))
      #(Negate(e1), Boolean)
    }
    Not(e) -> {
      use #(e1, te) <- result.try(type_check_exp(e, env))
      use _ <- result.map(check_type_equal(Boolean, te, e1))
      #(Not(e1), Boolean)
    }
    And(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(Boolean, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(Boolean, tb, b1))
      #(And(a1, b1), Boolean)
    }
    Or(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(Boolean, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(Boolean, tb, b1))
      #(Or(a1, b1), Boolean)
    }
    Cmp(Eq, a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(ta, tb, b1))
      #(Cmp(Eq, a1, b1), Boolean)
    }
    Cmp(op, a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(Integer, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(Integer, tb, b1))
      #(Cmp(op, a1, b1), Boolean)
    }
    Minus(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(Integer, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(Integer, tb, b1))
      #(Minus(a1, b1), Integer)
    }
    Plus(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(Integer, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(Integer, tb, b1))
      #(Plus(a1, b1), Integer)
    }
  }
}

fn check_type_equal(a: Type, b: Type, e: Expr) -> Result(Nil, TypeError) {
  case a == b {
    True -> Ok(Nil)
    False -> Error(TypeError(a, b, e))
  }
}
