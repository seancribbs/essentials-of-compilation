import gleam/result
import lustre
import lustre/attribute.{type Attribute, class}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, textarea}
import lustre/event

import eoc/compile

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(input: String, output: String)
}

type Msg {
  InputUpdated(input: String)
  Compile
}

fn init(_args) -> Model {
  Model("", "")
}

fn update(model: Model, msg: Msg) {
  case msg {
    InputUpdated(input) -> Model(..model, input:)
    Compile ->
      Model(..model, output: result.unwrap_both(compile.compile(model.input)))
  }
}

fn view(model: Model) -> Element(Msg) {
  div([class("max-w-xl mx-auto my-5")], [
    div([class("flex flex-row gap-2 flex-wrap")], [
      code_component([event.on_change(InputUpdated)], model.input),
      code_component([attribute.readonly(True)], model.output),
    ]),
    button(
      [
        class("rounded-md px-3 py-1 bg-green-400 shadow-sm"),
        event.on_click(Compile),
      ],
      [text("Compile")],
    ),
  ])
}

fn code_component(attrs: List(Attribute(Msg)), body: String) -> Element(Msg) {
  textarea(
    [
      class(
        "resize-y field-sizing-fixed size-max border border-slate-300 font-mono caret-black",
      ),
      attribute.autocomplete("off"),
      ..attrs
    ],
    body,
  )
}
