import eoc/langs/l_fun.{type Cmp, type Type, format_cmp, format_type}
import eoc/langs/pretty.{parenthesize}
import glam/doc
import gleam/int
import gleam/list

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
  VectorLength(v: Expr)
  VectorRef(v: Expr, index: Expr)
  VectorSet(v: Expr, index: Expr, value: Expr)
}

pub type Expr {
  Int(value: Int)
  Bool(value: Bool)
  Prim(op: PrimOp)
  Var(name: String)
  FunRef(name: String, arity: Int)
  Let(var: String, binding: Expr, expr: Expr)
  If(condition: Expr, if_true: Expr, if_false: Expr)
  SetBang(var: String, value: Expr)
  Begin(stmts: List(Expr), result: Expr)
  WhileLoop(condition: Expr, body: Expr)
  HasType(value: Expr, t: Type)
  Apply(function: Expr, arguments: List(Expr))
  Collect(amount: Int)
  Allocate(amount: Int, t: Type)
  GlobalValue(name: String)
}

pub type Definition {
  Definition(
    name: String,
    arguments: List(#(String, Type)),
    return: Type,
    body: Expr,
  )
}

pub type Program {
  Program(defs: List(Definition))
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
    Bool(value:) ->
      case value {
        False -> doc.from_string("#f")
        True -> doc.from_string("#t")
      }
    Var(name:) -> doc.from_string(name)
    Int(value:) -> pretty.int_to_doc(value)
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

    Apply(function:, arguments:) ->
      [format_expr(function), ..list.map(arguments, format_expr)]
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
    // Vector(fields:) -> [
    //   doc.from_string("vector"),
    //   ..list.map(fields, format_expr)
    // ]
    Void -> [doc.from_string("void")]
  }
  |> doc.concat_join(with: [doc.space])
}
