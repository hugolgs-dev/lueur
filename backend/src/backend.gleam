import envoy
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/option.{None}
import gleam/result
import mist

pub fn main() {
  let port =
    envoy.get("LUEUR_PORT")
    |> result.try(int.parse)
    |> result.unwrap(47_100)

  let assert Ok(_) =
    fn(req) {
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: fn(_conn) { #(Nil, None) },
            on_close: fn(_state) { Nil },
            handler: handle_ws,
          )
        _ ->
          response.new(404)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
    |> mist.new
    |> mist.bind("127.0.0.1")
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}

fn handle_ws(state, message, conn) {
  case message {
    mist.Text(text) -> {
      let assert Ok(_) = mist.send_text_frame(conn, "backend got: " <> text)
      mist.continue(state)
    }
    mist.Closed | mist.Shutdown -> mist.stop()
    _ -> mist.continue(state)
  }
}
