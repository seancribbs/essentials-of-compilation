import eoc/langs/l_tup.{type Cmp, type Type} as l
import eoc/langs/pretty.{int_to_doc, parenthesize}
import glam/doc
import gleam/dict
import gleam/io
import gleam/list

pub type Atm {
  Int(value: Int)
  Bool(value: Bool)
  Variable(v: String)
  Void
}

pub type PrimOp {
  Read
  Neg(a: Atm)
  Not(a: Atm)
  Cmp(op: Cmp, a: Atm, b: Atm)
  Plus(a: Atm, b: Atm)
  Minus(a: Atm, b: Atm)
  VectorRef(v: Atm, index: Atm)
  VectorSet(v: Atm, index: Atm, value: Atm)
  VectorLength(v: Atm)
}

pub type Expr {
  Atom(atm: Atm)
  Prim(op: PrimOp)
  Allocate(amount: Int, t: Type)
  GlobalValue(var: String)
}

pub type Stmt {
  Assign(var: String, expr: Expr)
  ReadStmt
  VectorSetStmt(v: Atm, index: Atm, value: Atm)
  Collect(amount: Int)
}

pub type Tail {
  Return(a: Expr)
  Seq(s: Stmt, t: Tail)
  Goto(label: String)
  If(cond: Expr, if_true: Tail, if_false: Tail)
}

pub type Blocks =
  dict.Dict(String, Tail)

pub type CProgram {
  CProgram(info: dict.Dict(String, List(String)), body: Blocks)
}

pub fn format_program(input: CProgram) -> doc.Document {
  input.body
  |> dict.to_list
  |> list.map(fn(item) { format_block(item.0, item.1) })
  |> doc.concat
  // |> doc.force_break
}

fn format_block(name: String, contents: Tail) -> doc.Document {
  let label = doc.concat([doc.from_string(name <> ":"), doc.line])

  contents
  |> format_tail()
  |> doc.prepend(label)
  |> doc.nest(2)
  |> doc.append_docs([doc.line, doc.line])
  |> doc.group
}

fn format_tail(t: Tail) -> doc.Document {
  case t {
    Goto(label:) -> doc.from_string("goto " <> label <> ";")
    If(cond:, if_true:, if_false:) ->
      doc.concat_join(
        [
          doc.concat([doc.from_string("if "), format_expr(cond)]),
          pretty.with_indent(format_tail(if_true), 2),
          doc.from_string("else"),
          pretty.with_indent(format_tail(if_false), 2),
        ],
        with: [doc.line],
      )
    Return(a:) ->
      doc.concat([
        doc.from_string("return "),
        format_expr(a),
        doc.from_string(";"),
      ])
    Seq(s:, t:) ->
      doc.concat_join([format_stmt(s), format_tail(t)], with: [doc.line])
  }
}

fn format_stmt(s: Stmt) -> doc.Document {
  case s {
    Assign(var:, expr:) ->
      doc.concat([
        doc.from_string(var),
        doc.space,
        doc.from_string("="),
        doc.space,
        format_expr(expr),
      ])

    Collect(amount:) ->
      [doc.from_string("collect"), int_to_doc(amount)]
      |> doc.concat_join([doc.space])
      |> parenthesize

    ReadStmt -> parenthesize(doc.from_string("read"))
    VectorSetStmt(v:, index:, value:) ->
      [
        doc.from_string("vector-set!"),
        format_atm(v),
        format_atm(index),
        format_atm(value),
      ]
      |> doc.concat_join(with: [doc.space])
      |> parenthesize
  }
  |> doc.append(doc.from_string(";"))
}

fn format_atm(a: Atm) -> doc.Document {
  case a {
    Bool(value:) ->
      case value {
        False -> doc.from_string("#f")
        True -> doc.from_string("#t")
      }
    Int(value:) -> int_to_doc(value)
    Variable(v:) -> doc.from_string(v)
    Void -> parenthesize(doc.from_string("void"))
  }
}

fn format_expr(e: Expr) -> doc.Document {
  case e {
    Atom(atm:) -> format_atm(atm)
    Allocate(amount:, t:) ->
      [doc.from_string("allocate"), int_to_doc(amount), l.format_type(t)]
      |> doc.concat_join(with: [doc.from_string(" ")])
      |> parenthesize
    GlobalValue(var:) ->
      [doc.from_string("global-value"), doc.from_string(var)]
      |> doc.concat_join(with: [doc.from_string(" ")])
      |> parenthesize
    Prim(op:) -> op |> format_op() |> parenthesize
  }
}

fn format_op(op: PrimOp) -> doc.Document {
  case op {
    Cmp(op:, a:, b:) -> [
      l.format_cmp(op),
      format_atm(a),
      format_atm(b),
    ]
    Minus(a:, b:) -> [
      doc.from_string("-"),
      format_atm(a),
      format_atm(b),
    ]
    Neg(a:) -> [
      doc.from_string("-"),
      format_atm(a),
    ]
    Not(a:) -> [doc.from_string("not"), format_atm(a)]
    Plus(a:, b:) -> [
      doc.from_string("+"),
      format_atm(a),
      format_atm(b),
    ]
    Read -> [doc.from_string("read")]
    VectorLength(v:) -> [
      doc.from_string("vector-length"),
      format_atm(v),
    ]
    VectorRef(v:, index:) -> [
      doc.from_string("vector-ref"),
      format_atm(v),
      format_atm(index),
    ]
    VectorSet(v:, index:, value:) -> [
      doc.from_string("vector-set!"),
      format_atm(v),
      format_atm(index),
      format_atm(value),
    ]
  }
  |> doc.concat_join(with: [doc.from_string(" ")])
}

pub fn main() {
  let p =
    CProgram(
      dict.from_list([]),
      dict.from_list([
        #(
          "block_1",
          Seq(
            Assign("alloc6", Allocate(1, l.VectorT([l.VectorT([l.IntegerT])]))),
            Seq(
              Assign(
                "_7",
                Prim(VectorSet(Variable("alloc6"), Int(0), Variable("vecinit5"))),
              ),
              Seq(
                Assign("tmp.7", Atom(Variable("alloc6"))),
                Seq(
                  Assign("tmp.8", Prim(VectorRef(Variable("tmp.7"), Int(0)))),
                  Return(Prim(VectorRef(Variable("tmp.8"), Int(0)))),
                ),
              ),
            ),
          ),
        ),
        #("block_2", Seq(Assign("_8", Atom(Void)), Goto("block_1"))),
        #("block_3", Seq(Collect(16), Goto("block_1"))),
        #(
          "block_4",
          Seq(
            Assign("alloc2", Allocate(1, l.VectorT([l.IntegerT]))),
            Seq(
              Assign(
                "_3",
                Prim(VectorSet(Variable("alloc2"), Int(0), Variable("vecinit1"))),
              ),
              Seq(
                Assign("vecinit5", Atom(Variable("alloc2"))),
                Seq(
                  Assign("tmp.4", GlobalValue("free_ptr")),
                  Seq(
                    Assign("tmp.5", Prim(Plus(Variable("tmp.4"), Int(16)))),
                    Seq(
                      Assign("tmp.6", GlobalValue("fromspace_end")),
                      If(
                        Prim(Cmp(l.Lt, Variable("tmp.5"), Variable("tmp.6"))),
                        Goto("block_2"),
                        Goto("block_3"),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        #("block_5", Seq(Assign("_4", Atom(Void)), Goto("block_4"))),
        #("block_6", Seq(Collect(16), Goto("block_4"))),
        #(
          "start",
          Seq(
            Assign("vecinit1", Atom(Int(42))),
            Seq(
              Assign("tmp.1", GlobalValue("free_ptr")),
              Seq(
                Assign("tmp.2", Prim(Plus(Variable("tmp.1"), Int(16)))),
                Seq(
                  Assign("tmp.3", GlobalValue("fromspace_end")),
                  If(
                    Prim(Cmp(l.Lt, Variable("tmp.2"), Variable("tmp.3"))),
                    Goto("block_5"),
                    Goto("block_6"),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    )

  p |> format_program |> doc.to_string(20) |> io.println
}
