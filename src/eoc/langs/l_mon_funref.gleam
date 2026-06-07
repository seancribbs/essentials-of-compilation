import eoc/langs/l_fun.{type Cmp, type Type, format_cmp, format_type}
import eoc/langs/pretty.{parenthesize}
import glam/doc
import gleam/int
import gleam/list

pub type Atm {
  Int(value: Int)
  Var(name: String)
  Bool(value: Bool)
  HasType(value: Atm, t: Type)
  Void
}

pub type PrimOp {
  Read
  Negate(value: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
  Not(value: Atm)
  Cmp(op: Cmp, a: Atm, b: Atm)
  VectorLength(v: Atm)
  VectorRef(v: Atm, index: Atm)
  VectorSet(v: Atm, index: Atm, value: Atm)
}

pub type Expr {
  Atomic(value: Atm)
  Prim(op: PrimOp)
  Let(var: String, binding: Expr, expr: Expr)
  If(condition: Expr, if_true: Expr, if_false: Expr)
  GetBang(var: String)
  SetBang(var: String, value: Expr)
  Begin(stmts: List(Expr), result: Expr)
  WhileLoop(condition: Expr, body: Expr)
  Collect(amount: Int)
  Allocate(amount: Int, t: Type)
  GlobalValue(name: String)
  FunRef(name: String, arity: Int)
  Apply(function: Atm, arguments: List(Atm))
}

pub type Program {
  Program(defs: List(Definition))
}

pub type Definition {
  Definition(
    name: String,
    arguments: List(#(String, Type)),
    return: Type,
    body: Expr,
  )
}

pub fn format_program(p: Program) -> doc.Document {
  p.defs
  |> list.map(format_def)
  |> doc.concat_join(with: [doc.line])
}

fn format_def(d: Definition) -> doc.Document {
  let arguments =
    d.arguments
    |> list.map(format_argument)

  [
    doc.from_string("define"),
    [doc.from_string(d.name), ..arguments]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize(),
    doc.from_string(":"),
    format_type(d.return),
    doc.line,
    format_expr(d.body),
  ]
  |> doc.concat_join(with: [doc.space])
  |> parenthesize()
}

fn format_argument(arg: #(String, Type)) -> doc.Document {
  [doc.from_string(arg.0), doc.from_string(" : "), format_type(arg.1)]
  |> doc.concat()
  |> doc.prepend(doc.from_string("["))
  |> doc.append(doc.from_string("]"))
}

fn format_expr(e: Expr) -> doc.Document {
  case e {
    Atomic(a) -> format_atomic(a)
    FunRef(name:, arity:) ->
      doc.from_string(name <> "/" <> int.to_string(arity))
    Begin(stmts:, result:) ->
      stmts
      |> list.map(format_expr)
      |> list.append([format_expr(result)])
      |> doc.concat_join(with: [doc.space])
      |> doc.force_break
      |> doc.prepend_docs([doc.from_string("begin"), doc.space])
      |> parenthesize()

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

    GetBang(var:) ->
      [doc.from_string("get!"), doc.from_string(var)]
      |> doc.concat_join(with: [doc.space])
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

    Apply(function:, arguments:) ->
      [format_atomic(function), ..list.map(arguments, format_atomic)]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
    Collect(amount:) ->
      [
        doc.from_string("collect"),
        doc.from_string(int.to_string(amount)),
      ]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
    Allocate(amount:, t:) ->
      [
        doc.from_string("allocate"),
        doc.from_string(int.to_string(amount)),
        format_type(t),
      ]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
    GlobalValue(name:) ->
      [doc.from_string("global-value"), doc.from_string(name)]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
  }
}

fn format_atomic(a: Atm) -> doc.Document {
  case a {
    Int(value:) -> doc.from_string(int.to_string(value))
    Var(name:) -> doc.from_string(name)
    Bool(value:) ->
      case value {
        False -> doc.from_string("#f")
        True -> doc.from_string("#t")
      }
    HasType(value:, t:) ->
      [doc.from_string("has-type"), format_atomic(value), format_type(t)]
      |> doc.concat_join(with: [doc.flex_space])
      |> parenthesize
    Void -> parenthesize(doc.from_string("void"))
  }
}

fn format_op(op: PrimOp) -> doc.Document {
  case op {
    Cmp(op:, a:, b:) -> [
      format_cmp(op),
      format_atomic(a),
      format_atomic(b),
    ]
    Minus(a:, b:) -> [
      doc.from_string("-"),
      format_atomic(a),
      format_atomic(b),
    ]
    Negate(value:) -> [
      doc.from_string("-"),
      format_atomic(value),
    ]
    Not(value:) -> [doc.from_string("not"), format_atomic(value)]
    Plus(a:, b:) -> [
      doc.from_string("+"),
      format_atomic(a),
      format_atomic(b),
    ]
    Read -> [doc.from_string("read")]
    VectorLength(v:) -> [
      doc.from_string("vector-length"),
      format_atomic(v),
    ]
    VectorRef(v:, index:) -> [
      doc.from_string("vector-ref"),
      format_atomic(v),
      format_atomic(index),
    ]
    VectorSet(v:, index:, value:) -> [
      doc.from_string("vector-set!"),
      format_atomic(v),
      format_atomic(index),
      format_atomic(value),
    ]
  }
  |> doc.concat_join(with: [doc.space])
}
