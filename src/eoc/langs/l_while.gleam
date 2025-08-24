import eoc/runtime
import gleam/dict
import gleam/list
import gleam/result

pub type Type {
  IntegerT
  BooleanT
  VoidT
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
  Void
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
  SetBang(var: String, value: Expr)
  Begin(stmts: List(Expr), result: Expr)
  WhileLoop(condition: Expr, body: Expr)
}

pub type Program {
  Program(body: Expr)
}

type Env =
  dict.Dict(String, IValue)

pub type IValue {
  IntValue(v: Int)
  BoolValue(v: Bool)
  VoidValue
}

pub fn interpret(p: Program) -> IValue {
  interpret_exp(p.body, dict.new()).0
}

fn interpret_exp(e: Expr, env: Env) -> #(IValue, Env) {
  case e {
    Int(value) -> #(IntValue(value), env)
    Prim(op) -> interpret_op(op, env)
    Var(name) -> #(get_var(env, name), env)
    Let(var, binding, expr) -> {
      let #(result, env1) = interpret_exp(binding, env)
      let new_env = dict.insert(env1, var, result)
      interpret_exp(expr, new_env)
    }
    Bool(value) -> #(BoolValue(value), env)
    If(c, t, e) -> {
      case interpret_exp(c, env) {
        #(BoolValue(True), new_env) -> interpret_exp(t, new_env)
        #(BoolValue(False), new_env) -> interpret_exp(e, new_env)
        _ -> panic as "invalid boolean expression"
      }
    }
    SetBang(var:, value:) -> {
      let #(result, env1) = interpret_exp(value, env)
      #(VoidValue, dict.insert(env1, var, result))
    }
    Begin(stmts:, result:) -> {
      let env1 =
        list.fold(stmts, env, fn(acc, stmt) {
          let #(_, env1) = interpret_exp(stmt, acc)
          env1
        })
      interpret_exp(result, env1)
    }
    WhileLoop(condition:, body:) -> {
      case interpret_exp(condition, env) {
        #(BoolValue(False), e) -> #(VoidValue, e)
        #(BoolValue(True), e) -> {
          let #(_, e2) = interpret_exp(body, e)
          interpret_exp(WhileLoop(condition:, body:), e2)
        }
        _ -> panic as "invalid boolean expression"
      }
    }
  }
}

fn interpret_op(op: PrimOp, env: Env) -> #(IValue, Env) {
  case op {
    Negate(v) -> {
      let assert #(IntValue(i), e1) = interpret_exp(v, env)
      #(IntValue(-i), e1)
    }
    Minus(a, b) -> {
      let assert #(IntValue(av), e1) = interpret_exp(a, env)
      let assert #(IntValue(bv), e2) = interpret_exp(b, e1)
      #(IntValue(av - bv), e2)
    }
    Plus(a, b) -> {
      let assert #(IntValue(av), e1) = interpret_exp(a, env)
      let assert #(IntValue(bv), e2) = interpret_exp(b, e1)
      #(IntValue(av + bv), e2)
    }
    Read -> #(IntValue(runtime.read_int()), env)
    And(a, b) -> {
      case interpret_exp(a, env) {
        #(BoolValue(True), e1) -> {
          let assert #(BoolValue(bv), e2) = interpret_exp(b, e1)
          #(BoolValue(bv), e2)
        }
        #(BoolValue(False), e1) -> {
          #(BoolValue(False), e1)
        }
        _ -> panic as "non-boolean expression not valid in `and`"
      }
    }
    Or(a, b) -> {
      case interpret_exp(a, env) {
        #(BoolValue(True), e1) -> #(BoolValue(True), e1)
        #(BoolValue(False), e1) -> {
          let assert #(BoolValue(bv), e2) = interpret_exp(b, e1)
          #(BoolValue(bv), e2)
        }
        _ -> panic as "non-boolean expression not valid in `or`"
      }
    }
    Not(e) -> {
      let assert #(BoolValue(v), e1) = interpret_exp(e, env)
      #(BoolValue(!v), e1)
    }
    Cmp(Eq, a, b) -> {
      let #(av, e1) = interpret_exp(a, env)
      let #(bv, e2) = interpret_exp(b, e1)
      case av, bv {
        IntValue(ai), IntValue(bi) -> #(BoolValue(ai == bi), e2)
        BoolValue(ab), BoolValue(bb) -> #(BoolValue(ab == bb), e2)
        VoidValue, VoidValue -> #(BoolValue(True), e2)
        _, _ -> panic as "mismatched types in eq? expression"
      }
    }
    Cmp(op, a, b) -> {
      let assert #(IntValue(av), e1) = interpret_exp(a, env)
      let assert #(IntValue(bv), e2) = interpret_exp(b, e1)
      #(
        case op {
          Gt -> BoolValue(av > bv)
          Gte -> BoolValue(av >= bv)
          Lt -> BoolValue(av < bv)
          Lte -> BoolValue(av <= bv)
          Eq -> panic as "unreachable branch"
        },
        e2,
      )
    }
    Void -> #(VoidValue, env)
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
    Ok(#(expr, IntegerT)) -> Ok(Program(expr))
    Ok(#(expr, BooleanT)) -> Error(TypeError(IntegerT, BooleanT, expr))
    Ok(#(expr, VoidT)) -> Error(TypeError(IntegerT, VoidT, expr))
    Error(err) -> Error(err)
  }
}

pub fn type_check_exp(e: Expr, env: TypeEnv) -> Result(#(Expr, Type), TypeError) {
  case e {
    Bool(_) -> Ok(#(e, BooleanT))
    Int(_) -> Ok(#(e, IntegerT))
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
      use _ <- result.try(check_type_equal(BooleanT, tc, c1))
      use #(t1, tt) <- result.try(type_check_exp(thn, env))
      use #(e1, te) <- result.try(type_check_exp(els, env))
      use _ <- result.map(check_type_equal(tt, te, e1))
      #(If(c1, t1, e1), te)
    }
    Begin(stmts, result) -> {
      let stmts =
        stmts
        |> list.reverse
        |> list.fold_until(Ok([]), fn(acc, stmt) {
          case type_check_exp(stmt, env) {
            Ok(#(s1, _)) -> list.Continue(result.map(acc, fn(l) { [s1, ..l] }))
            Error(e) -> list.Stop(Error(e))
          }
        })
      use s2 <- result.try(stmts)
      use #(r1, tr) <- result.map(type_check_exp(result, env))
      #(Begin(s2, r1), tr)
    }
    SetBang(var:, value:) -> {
      use #(v1, tval) <- result.try(type_check_exp(value, env))
      use #(_, tvar) <- result.try(type_check_exp(Var(var), env))
      use _ <- result.map(check_type_equal(tvar, tval, SetBang(var:, value: v1)))
      #(SetBang(var:, value: v1), VoidT)
    }
    WhileLoop(condition:, body:) -> {
      use #(c1, tc) <- result.try(type_check_exp(condition, env))
      use _ <- result.try(check_type_equal(BooleanT, tc, c1))
      use #(b1, _) <- result.map(type_check_exp(body, env))
      #(WhileLoop(condition: c1, body: b1), VoidT)
    }
  }
}

pub fn type_check_op(
  p: PrimOp,
  env: TypeEnv,
) -> Result(#(PrimOp, Type), TypeError) {
  case p {
    Read -> Ok(#(Read, IntegerT))
    Negate(e) -> {
      use #(e1, te) <- result.try(type_check_exp(e, env))
      use _ <- result.map(check_type_equal(BooleanT, te, e1))
      #(Negate(e1), BooleanT)
    }
    Not(e) -> {
      use #(e1, te) <- result.try(type_check_exp(e, env))
      use _ <- result.map(check_type_equal(BooleanT, te, e1))
      #(Not(e1), BooleanT)
    }
    And(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(BooleanT, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(BooleanT, tb, b1))
      #(And(a1, b1), BooleanT)
    }
    Or(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(BooleanT, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(BooleanT, tb, b1))
      #(Or(a1, b1), BooleanT)
    }
    Cmp(Eq, a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(ta, tb, b1))
      #(Cmp(Eq, a1, b1), BooleanT)
    }
    Cmp(op, a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(IntegerT, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(IntegerT, tb, b1))
      #(Cmp(op, a1, b1), BooleanT)
    }
    Minus(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(IntegerT, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(IntegerT, tb, b1))
      #(Minus(a1, b1), IntegerT)
    }
    Plus(a, b) -> {
      use #(a1, ta) <- result.try(type_check_exp(a, env))
      use _ <- result.try(check_type_equal(IntegerT, ta, a1))
      use #(b1, tb) <- result.try(type_check_exp(b, env))
      use _ <- result.map(check_type_equal(IntegerT, tb, b1))
      #(Plus(a1, b1), IntegerT)
    }
    Void -> {
      Ok(#(Void, VoidT))
    }
  }
}

fn check_type_equal(a: Type, b: Type, e: Expr) -> Result(Nil, TypeError) {
  case a == b {
    True -> Ok(Nil)
    False -> Error(TypeError(a, b, e))
  }
}
