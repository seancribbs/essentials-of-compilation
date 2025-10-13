import glam/doc.{type Document}
import gleam/bool
import gleam/int
import gleam/string

pub fn parenthesize(document: Document) -> Document {
  document
  |> doc.prepend(doc.from_string("("))
  |> doc.append(doc.from_string(")"))
  |> doc.nest(by: 2)
  |> doc.group
}

pub fn int_to_doc(i: Int) -> Document {
  i |> int.to_string |> doc.from_string
}

pub fn bool_to_doc(b: Bool) -> Document {
  b
  |> bool.to_string()
  |> string.lowercase()
  |> doc.from_string()
}

pub fn with_indent(d: Document, amount: Int) -> Document {
  doc.concat([doc.from_string(string.repeat(" ", amount)), d])
}
