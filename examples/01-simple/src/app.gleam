import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/effect.{type Effect}
import modem

pub fn main() {
  lustre.application(init, update, view)
}

pub type Route {
  Wibble
  Wobble
}

fn init(_) -> #(Route, Effect(Msg)) {
  #(Wibble, modem.init(on_url_change))
}

fn on_url_change(uri: Uri) -> Msg {
  case uri.path_segments(uri.path) {
    ["wibble"] -> OnRouteChange(Wibble)
    ["wobble"] -> OnRouteChange(Wobble)
    _ -> OnRouteChange(Wibble)
  }
}

pub type Msg {
  OnRouteChange(Route)
}

fn update(_, msg: Msg) -> #(Route, Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> #(route, effect.none())
  }
}

fn view(route: Route) -> Element(Msg) {
  html.div([], [
    html.nav([], [
      html.a([attribute.href("/wibble")], [element.text("Go to wibble")]),
      html.a([attribute.href("/wobble")], [element.text("Go to wobble")]),
    ]),
    case route {
      Wibble -> html.h1([], [element.text("You're on wibble")])
      Wobble -> html.h1([], [element.text("You're on wobble")])
    },
  ])
}
