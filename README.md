# modem

[![Package Version](https://img.shields.io/hexpm/v/modem)](https://hex.pm/packages/modem)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/modem/)

Modem is a little library for Lustre that helps you manage navigation and URLs in
the browser. It converts url requests into messages that you can handle in your
app's update function. Modem isn't a router, but it can help you build one!

## Quickstart

Getting started with modem is easy! Most application's can get by with pattern
matching on a url's path: no complicated router setup required. Let's see what
that looks like with modem:

```sh
gleam add lustre modem
```

```gleam
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

```
