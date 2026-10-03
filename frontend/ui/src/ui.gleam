import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/effect.{type Effect}
import lustre/element/html
import lustre/event

pub type WebSocket

@external(javascript, "./socket_ffi.mjs", "connect")
fn ws_connect(
  url: String,
  on_open: fn(WebSocket) -> Nil,
  on_message: fn(String) -> Nil,
  on_close: fn() -> Nil,
) -> Nil

@external(javascript, "./socket_ffi.mjs", "send")
fn ws_send(socket: WebSocket, text: String) -> Nil

@external(javascript, "./socket_ffi.mjs", "after")
fn after(ms: Int, callback: fn() -> Nil) -> Nil

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

type Model {
  Model(socket: Option(WebSocket), log: List(String))
}

pub type Msg {
  Connected(WebSocket)
  Received(String)
  Disconnected
  Reconnect
  PingClicked
}

fn connect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    ws_connect(
      "ws://127.0.0.1:47100/ws",
      fn(socket) { dispatch(Connected(socket)) },
      fn(text) { dispatch(Received(text)) },
      fn() { dispatch(Disconnected) },
    )
  })
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(socket: None, log: []), connect())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Connected(socket) -> #(Model(..model, socket: Some(socket)), effect.none())
    Received(text) -> #(Model(..model, log: [text, ..model.log]), effect.none())
    // Backend may still be compiling on startup: retry every 500ms
    Disconnected -> #(
      Model(..model, socket: None),
      effect.from(fn(dispatch) { after(500, fn() { dispatch(Reconnect) }) }),
    )
    Reconnect -> #(model, connect())
    PingClicked ->
      case model.socket {
        Some(socket) -> #(model, effect.from(fn(_) { ws_send(socket, "ping") }))
        None -> #(model, effect.none())
      }
  }
}

fn view(model: Model) {
  let status = case model.socket {
    Some(_) -> "connected"
    None -> "connecting…"
  }
  html.div([], [
    html.h1([], [html.text("Lueur: " <> status)]),
    html.button([event.on_click(PingClicked)], [html.text("Ping backend")]),
    html.ul([], list.map(model.log, fn(line) { html.li([], [html.text(line)]) })),
  ])
}
