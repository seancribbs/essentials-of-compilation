import eoc/langs/pretty.{parenthesize}
import eoc/runtime
import glam/doc
import gleam/dict
import gleam/list
import gleam/option
import gleam/pair
import gleam/result

pub type Type {
  IntegerT
  BooleanT
  VoidT
  VectorT(List(Type))
}

pub type TypeError {
  TypeError(expected: Type, actual: Type, expression: Expr)
  VectorIndexOutOfBounds(actual: Int, size: Int)
  VectorIndexIsNotInteger(expr: Expr)
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
  Vector(fields: List(Expr))
  VectorLength(v: Expr)
  VectorRef(v: Expr, index: Expr)
  VectorSet(v: Expr, index: Expr, value: Expr)
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
  HasType(value: Expr, t: Type)
}

pub type Program {
  Program(body: Expr)
}

type Heap =
  dict.Dict(Int, List(IValue))

type Env {
  Env(vars: dict.Dict(String, IValue), heap: Heap)
}

fn new_env() -> Env {
  Env(dict.new(), dict.new())
}

fn bind_var(e: Env, v: String, value: IValue) -> Env {
  Env(..e, vars: dict.insert(e.vars, v, value))
}

fn allocate_vec(e: Env, fields: List(IValue)) -> #(IValue, Env) {
  let next = dict.size(e.heap)
  #(HeapRef(next), update_heap(e, next, fields))
}

fn get_heap(e: Env, i: Int) -> Result(List(IValue), Nil) {
  dict.get(e.heap, i)
}

fn update_heap(e: Env, i: Int, fields: List(IValue)) -> Env {
  Env(..e, heap: dict.insert(e.heap, i, fields))
}

pub type IValue {
  IntValue(v: Int)
  BoolValue(v: Bool)
  VoidValue
  HeapRef(i: Int)
}

pub fn interpret(p: Program) -> IValue {
  interpret_exp(p.body, new_env()).0
}

fn interpret_exp(e: Expr, env: Env) -> #(IValue, Env) {
  case e {
    Int(value) -> #(IntValue(value), env)
    Prim(op) -> interpret_op(op, env)
    Var(name) -> #(get_var(env, name), env)
    Let(var, binding, expr) -> {
      let #(result, env1) = interpret_exp(binding, env)
      let new_env = bind_var(env1, var, result)
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
      #(VoidValue, bind_var(env1, var, result))
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
    HasType(value:, t: _) -> interpret_exp(value, env)
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
        HeapRef(h1), HeapRef(h2) -> #(BoolValue(h1 == h2), e2)
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
    Vector(fields:) -> {
      let #(env, field_values) =
        list.map_fold(fields, env, fn(env, f) {
          pair.swap(interpret_exp(f, env))
        })
      allocate_vec(env, field_values)
    }
    VectorLength(v:) -> {
      let assert #(HeapRef(i), env) = interpret_exp(v, env)
      let assert Ok(vfs) = get_heap(env, i)
      #(IntValue(list.length(vfs)), env)
    }
    VectorRef(v:, index:) -> {
      let assert Int(i) = index
      let assert #(HeapRef(ref), env) = interpret_exp(v, env)
      let assert Ok(vfs) = get_heap(env, ref)
      let assert Ok(val) = list.first(list.drop(vfs, i))
      #(val, env)
    }
    VectorSet(v:, index:, value:) -> {
      let assert Int(i) = index
      let assert #(HeapRef(ref), env) = interpret_exp(v, env)
      let assert Ok(vfs) = get_heap(env, ref)
      let assert #(pred, [_field, ..succ]) = list.split(vfs, i)
      let #(new_field, env) = interpret_exp(value, env)
      let env = update_heap(env, ref, list.append(pred, [new_field, ..succ]))
      #(VoidValue, env)
    }
  }
}

fn get_var(env: Env, name: String) -> IValue {
  case dict.get(env.vars, name) {
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
    Ok(#(expr, v)) -> Error(TypeError(IntegerT, v, expr))
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
    Prim(Vector(e)) -> {
      use #(op, t) <- result.map(type_check_op(Vector(e), env))
      #(HasType(value: Prim(op), t:), t)
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
    HasType(value: _, t:) -> {
      Ok(#(e, t))
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
      use _ <- result.map(check_type_equal(IntegerT, te, e1))
      #(Negate(e1), IntegerT)
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
    Vector(exprs) -> {
      let checked =
        exprs
        |> list.reverse
        |> list.fold_until(Ok(#([], [])), fn(acc, expr) {
          case type_check_exp(expr, env) {
            Ok(#(e1, t1)) ->
              list.Continue(
                result.map(acc, fn(ets) { #([e1, ..ets.0], [t1, ..ets.1]) }),
              )
            Error(e) -> list.Stop(Error(e))
          }
        })
      use #(exprs, types) <- result.map(checked)
      #(Vector(exprs), VectorT(types))
    }
    VectorLength(v:) -> {
      use #(e, t) <- result.try(type_check_exp(v, env))
      use _ <- result.map(is_vector_type(e, t))
      #(VectorLength(maybe_wrap_with_type(e, t)), t)
    }
    VectorRef(v:, index:) -> {
      use #(v1, t1) <- result.try(type_check_exp(v, env))
      use item_types <- result.try(is_vector_type(v1, t1))
      use i <- result.map(check_vector_index(index, list.length(item_types)))
      let assert Ok(item_type) = list.first(list.drop(item_types, i))
      #(VectorRef(maybe_wrap_with_type(v1, t1), index), item_type)
    }
    VectorSet(v:, index:, value:) -> {
      use #(v1, t1) <- result.try(type_check_exp(v, env))
      use item_types <- result.try(is_vector_type(v1, t1))
      use i <- result.try(check_vector_index(index, list.length(item_types)))
      use #(val1, vt1) <- result.try(type_check_exp(value, env))
      let assert Ok(item_type) = list.first(list.drop(item_types, i))
      use _ <- result.map(check_type_equal(
        item_type,
        vt1,
        Prim(VectorSet(v1, index, val1)),
      ))
      #(VectorSet(maybe_wrap_with_type(v1, t1), index, val1), VoidT)
    }
  }
}

fn check_type_equal(a: Type, b: Type, e: Expr) -> Result(Nil, TypeError) {
  case a == b {
    True -> Ok(Nil)
    False -> Error(TypeError(a, b, e))
  }
}

fn check_vector_index(e: Expr, length: Int) -> Result(Int, TypeError) {
  case e {
    Int(i) if i < length -> Ok(i)
    Int(i) -> Error(VectorIndexOutOfBounds(i, length))
    _ -> Error(VectorIndexIsNotInteger(e))
  }
}

fn is_vector_type(e: Expr, t: Type) -> Result(List(Type), TypeError) {
  case t {
    VectorT(ts) -> Ok(ts)
    _ -> Error(TypeError(t, VectorT([]), e))
  }
}

fn maybe_wrap_with_type(e: Expr, t: Type) -> Expr {
  case e {
    HasType(_, _) -> e
    other -> HasType(other, t)
  }
}

pub fn type_at_index(t: Type, index: Int) -> option.Option(Type) {
  case t {
    VectorT(fields) ->
      fields
      |> list.drop(index)
      |> list.first()
      |> option.from_result()
    _ -> option.None
  }
}

pub fn format_program(p: Program) -> doc.Document {
  format_expr(p.body)
}

fn format_expr(e: Expr) -> doc.Document {
  case e {
    Bool(value:) ->
      case value {
        False -> doc.from_string("#f")
        True -> doc.from_string("#t")
      }
    Var(name:) -> doc.from_string(name)
    Int(value:) -> pretty.int_to_doc(value)
    Begin(stmts:, result:) ->
      stmts
      |> list.map(format_expr)
      |> list.append([format_expr(result)])
      |> doc.concat_join(with: [doc.space])
      |> doc.force_break
      |> doc.prepend_docs([doc.from_string("begin"), doc.space])
      |> parenthesize()

    HasType(value:, t:) ->
      [doc.from_string("has-type"), format_expr(value), format_type(t)]
      |> doc.concat_join(with: [doc.flex_space])
      |> parenthesize

    If(condition:, if_true:, if_false:) ->
      [
        doc.concat([
          doc.from_string("if"),
          doc.from_string(" "),
          format_expr(condition),
        ]),
        format_expr(if_true),
        format_expr(if_false),
      ]
      |> doc.concat_join(with: [doc.line])
      |> parenthesize
    Let(var:, binding:, expr:) ->
      [
        doc.concat([
          doc.from_string("let"),
          doc.from_string(" (["),
          doc.from_string(var),
          doc.from_string(" "),
          format_expr(binding),
          doc.from_string("])"),
        ]),
        format_expr(expr),
      ]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
    WhileLoop(condition:, body:) ->
      [
        doc.concat([
          doc.from_string("while"),
          doc.from_string(" "),
          format_expr(condition),
        ]),
        format_expr(body),
      ]
      |> doc.concat_join(with: [doc.space])
      |> doc.force_break
      |> parenthesize

    SetBang(var:, value:) ->
      [
        doc.from_string("set!"),
        doc.from_string(var),
        format_expr(value),
      ]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize

    Prim(op:) -> op |> format_op |> parenthesize
  }
}

fn format_op(op: PrimOp) -> doc.Document {
  case op {
    Cmp(op:, a:, b:) -> [
      format_cmp(op),
      format_expr(a),
      format_expr(b),
    ]
    Minus(a:, b:) -> [
      doc.from_string("-"),
      format_expr(a),
      format_expr(b),
    ]
    Negate(value:) -> [
      doc.from_string("-"),
      format_expr(value),
    ]
    Not(a:) -> [doc.from_string("not"), format_expr(a)]
    Plus(a:, b:) -> [
      doc.from_string("+"),
      format_expr(a),
      format_expr(b),
    ]
    Read -> [doc.from_string("read")]
    VectorLength(v:) -> [
      doc.from_string("vector-length"),
      format_expr(v),
    ]
    VectorRef(v:, index:) -> [
      doc.from_string("vector-ref"),
      format_expr(v),
      format_expr(index),
    ]
    VectorSet(v:, index:, value:) -> [
      doc.from_string("vector-set!"),
      format_expr(v),
      format_expr(index),
      format_expr(value),
    ]
    And(a:, b:) -> [
      doc.from_string("and"),
      format_expr(a),
      format_expr(b),
    ]
    Or(a:, b:) -> [doc.from_string("or"), format_expr(a), format_expr(b)]
    Vector(fields:) -> [
      doc.from_string("vector"),
      ..list.map(fields, format_expr)
    ]
    Void -> [doc.from_string("void")]
  }
  |> doc.concat_join(with: [doc.space])
}

pub fn format_cmp(op: Cmp) -> doc.Document {
  case op {
    Eq -> "eq?"
    Gt -> ">"
    Gte -> ">="
    Lt -> "<"
    Lte -> "<="
  }
  |> doc.from_string
}

pub fn format_type(t: Type) -> doc.Document {
  case t {
    BooleanT -> doc.from_string("Boolean")
    IntegerT -> doc.from_string("Integer")
    VectorT(fields) ->
      [doc.from_string("Vector"), ..list.map(fields, format_type)]
      |> doc.concat_join(with: [doc.flex_space])
      |> parenthesize
    VoidT -> doc.from_string("Void")
  }
}
