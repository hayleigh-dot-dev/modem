# modem

[![Package Version](https://img.shields.io/hexpm/v/modem)](https://hex.pm/packages/modem)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/modem/)

> **modem**: a device that converts signals produced by one type of device (such
> as a computer) to a form compatible with another (such as a telephone) – [Merriam-Webster](https://www.merriam-webster.com/dictionary/modem)

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

Here's a breakdown of what's happening:

- We define a `Route` type that represents the page or route we're currently on.

- `modem.init` is an [`Effect`](https://hexdocs.pm/lustre/4.0.0-rc.2/lustre/effect.html#Effect)
  that intercepts clicks to local links and browser back/forward navigation and
  lets you handle them.

- `on_url_change` is a function we write that takes an incoming [`Uri`](https://hexdocs.pm/gleam_stdlib/gleam/uri.html#Uri)
  and converts it to our app's `Msg` type.

- In our `view` we can just use normal `html.a.` elements: no special link component
  necessary. Pattern matching on the `Route` type lets us render different content
  for each page.
