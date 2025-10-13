import eoc/ui/button.{button}
import gleam/list
import gleam/result
import lustre
import lustre/attribute.{type Attribute, class, style}
import lustre/element.{type Element, text}
import lustre/element/html.{div, textarea}
import lustre/event

import eoc/compile.{type Pass, pass_order, pass_to_string, string_to_pass}
import eoc/ui/theme

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(input: String, output: String, pass: Pass)
}

type Msg {
  InputUpdated(input: String)
  PassSelected(pass: String)
  Compile
  Interpet
}

fn init(_args) -> Model {
  Model("", "", compile.ExplicateControl)
}

fn update(model: Model, msg: Msg) {
  case msg {
    InputUpdated(input) -> Model(..model, input:)
    Compile ->
      Model(
        ..model,
        output: result.unwrap_both(compile.compile(model.input, model.pass)),
      )
    Interpet ->
      Model(..model, output: result.unwrap_both(compile.interpret(model.input)))
    PassSelected(pass:) -> Model(..model, pass: string_to_pass(pass))
  }
}

fn view(model: Model) -> Element(Msg) {
  use <- theme.inject(theme.default())
  div([class("my-1 px-3")], [
    div([class("p-2 flex flex-row")], [
      html.h1(
        [
          theme.use_base(),
          style("font-family", theme.font.heading),
          style("font-size", theme.spacing.lg),
          class("mr-2"),
        ],
        [text("Essentials of Compilation")],
      ),
      html.select(
        [
          theme.use_primary(),
          class("mr-2"),
          event.on_change(PassSelected),
        ],
        pass_order
          |> list.map(fn(p) {
            html.option(
              [attribute.selected(model.pass == p)],
              pass_to_string(p),
            )
          }),
      ),
      button(
        [
          theme.use_primary(),
          class("mr-2"),
          event.on_click(Compile),
        ],
        [text("Compile")],
      ),
      button(
        [
          theme.use_secondary(),
          event.on_click(Interpet),
        ],
        [text("Interpet")],
      ),
    ]),
    div([class("w-screen flex flex-row gap-2 h-svh")], [
      code_component([event.on_change(InputUpdated)], model.input),
      code_component([attribute.readonly(True)], model.output),
    ]),
  ])
}

fn code_component(attrs: List(Attribute(Msg)), body: String) -> Element(Msg) {
  div([class("grow")], [
    textarea(
      [
        style("font-family", theme.font.code),
        style("font-size", theme.spacing.lg),
        style("background-color", theme.colour.bg_subtle),
        class("resize-none h-full w-full focus:border-none"),
        attribute.autocomplete("off"),
        ..attrs
      ],
      body,
    ),
  ])
}
