// IMPORTS ---------------------------------------------------------------------

import apps/example
import birdie
import gleam/function
import gleam/string
import gleeunit
import gleeunit/should
import lustre/dev/query
import lustre/dev/simulate
import lustre/element
import modem

// TESTS -----------------------------------------------------------------------

pub fn simulate_single_navigation_test() {
  let app =
    simulate.application(example.init, example.update, example.view)
    |> simulate.start(Nil)
    |> modem.simulate(
      link: query.element(query.attribute("href", "/wobble")),
      base: "http://localhost:1234",
      on_url_change: example.on_url_change,
    )

  let assert Ok(el) =
    query.find(
      in: simulate.view(app),
      matching: query.element(matching: query.text("You're on wobble")),
    )

  el
  |> element.to_readable_string
  |> birdie.snap("Simulate a single navigation")
}

pub fn simulate_invalid_base_url_test() {
  let app =
    simulate.application(example.init, example.update, example.view)
    |> simulate.start(Nil)
    |> modem.simulate(
      link: query.element(query.attribute("href", "/wobble")),
      base: "invalid-url",
      on_url_change: example.on_url_change,
    )

  simulate.history(app)
  |> string.inspect
  |> birdie.snap("Simulate an invalid base URL")
}
