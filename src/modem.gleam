//// > **modem**: a device that converts signals produced by one type of device
//// > (such as a computer) to a form compatible with another (such as a
//// > telephone) –  [Merriam-Webster](https://www.merriam-webster.com/dictionary/modem)
////
//// Modem is a little library for Lustre that helps you manage navigation and URLs
//// in the browser. It converts url requests into messages that you can handle
//// in your app's update function. Modem isn't a router, but it can help you
//// build one!
////
////

// IMPORTS ---------------------------------------------------------------------

import gleam/bool
import gleam/option.{type Option, None}
import gleam/uri.{type Uri, Uri}
import lustre
import lustre/effect.{type Effect}

// CONSTANTS -------------------------------------------------------------------

const relative: Uri = Uri(
  scheme: None,
  userinfo: None,
  host: None,
  port: None,
  path: "",
  query: None,
  fragment: None,
)

// TYPES -----------------------------------------------------------------------

pub type Options {
  Options(
    /// Enable this option if you'd like to trigger your url change handler when
    /// a link to the same domain is clicked. When enabled, internal links will
    /// _always_ update the url shown in the browser's address bar but they _won't_
    /// trigger a page load.
    ///
    handle_internal_links: Bool,
    /// Enable this option if you'd like to trigger your url change handler even
    /// when the link is to some external domain. You might want to do this for
    /// example to save some state in your app before the user navigates away.
    ///
    /// You will need to manually call [`load`](#load) to actually navigate to
    /// the external link!
    ///
    handle_external_links: Bool,
  )
}

// QUERIES ---------------------------------------------------------------------

/// Get the `Uri` of the page when it first loaded. This can be useful to read
/// in your own app's `init` function so you can choose the correct initial
/// route for your app.
///
/// To subscribe to changes in the uri when a user navigates around your app, see
/// the [`init`](#init) and [`advanced`](#advanced) functions.
///
/// > **Note**: this function is only meaningful when run in the browser. When
/// > run in a backend JavaScript environment or in Erlang this function will
/// > always fail.
///
@external(javascript, "./modem.ffi.mjs", "do_initial_uri")
pub fn initial_uri() -> Result(Uri, Nil) {
  Error(Nil)
}

// EFFECTS ---------------------------------------------------------------------

/// Initialise a simple modem that intercepts internal links and sends them to
/// your update function through the provided handler.
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn init(handler: fn(Uri) -> msg) -> Effect(msg) {
  use dispatch <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)
  use uri <- do_init

  uri
  |> handler
  |> dispatch
}

@external(javascript, "./modem.ffi.mjs", "do_init")
fn do_init(_handler: fn(Uri) -> Nil) -> Nil {
  Nil
}

/// Initialise an advanced modem that lets you configure what types of links to
/// intercept. Take a look at the [`Options`](#options) type for info on what
/// can be configured.
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn advanced(options: Options, handler: fn(Uri) -> msg) -> Effect(msg) {
  use dispatch <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)
  use uri <- do_advanced(_, options)

  uri
  |> handler
  |> dispatch
}

@external(javascript, "./modem.ffi.mjs", "do_init")
fn do_advanced(_handler: fn(Uri) -> Nil, _options: Options) -> Nil {
  Nil
}

/// Push a new relative route onto the browser's history stack. This will not
/// trigger a full page reload.
///
/// **Note**: if you push a new uri while the user has navigated using the back
/// or forward buttons, you will clear any forward history in the stack!
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn push(
  path: String,
  query: Option(String),
  fragment: Option(String),
) -> Effect(msg) {
  use _ <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)

  do_push(Uri(..relative, path: path, query: query, fragment: fragment))
}

@external(javascript, "./modem.ffi.mjs", "do_push")
fn do_push(_uri: Uri) -> Nil {
  Nil
}

/// Replace the current uri in the browser's history stack with a new relative
/// route. This will not trigger a full page reload.
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn replace(
  path: String,
  query: Option(String),
  fragment: Option(String),
) -> Effect(msg) {
  use _ <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)

  do_replace(Uri(..relative, path: path, query: query, fragment: fragment))
}

@external(javascript, "./modem.ffi.mjs", "do_replace")
fn do_replace(_uri: Uri) -> Nil {
  Nil
}

/// Load a new uri. This will always trigger a full page reload even if the uri
/// is relative or the same as the current page.
///
/// **Note**: if you load a new uri while the user has navigated using the back
/// or forward buttons, you will clear any forward history in the stack!
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn load(uri: Uri) -> Effect(msg) {
  use _ <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)

  do_load(uri)
}

@external(javascript, "./modem.ffi.mjs", "do_load")
fn do_load(_uri: Uri) -> Nil {
  Nil
}

/// The browser maintains a history stack of all the url's the user has visited.
/// This function lets you move forward the given number of steps in that stack.
/// If you reach the end of the stack, further attempts to go forward will do
/// nothing (unfortunately time travel is not quite possible yet).
///
/// **Note**: you can go _too far forward_ and end up navigating the user off your
/// app if you're not careful.
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn forward(steps: Int) -> Effect(msg) {
  use _ <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)

  do_forward(steps)
}

@external(javascript, "./modem.ffi.mjs", "do_forward")
fn do_forward(_steps: Int) -> Nil {
  Nil
}

/// The browser maintains a history stack of all the url's the user has visited.
/// This function lets you move back the given number of steps in that stack.
/// If you reach the beginning of the stack, further attempts to go back will do
/// nothing (unfortunately time travel is not quite possible yet).
///
/// **Note**: if you navigate back and then [`push`](#push) a new url, you will
/// clear the forward history of the stack.
///
/// **Note**: you can go _too far back_ and end up navigating the user off your
/// app if you're not careful.
///
/// > **Note**: this effect is only meaningful in the browser. When executed in
/// > a backend JavaScript environment or in Erlang this effect will always be
/// > equivalent to `effect.none()`
///
pub fn back(steps: Int) -> Effect(msg) {
  use _ <- effect.from
  use <- bool.guard(!lustre.is_browser(), Nil)

  do_back(steps)
}

@external(javascript, "./modem.ffi.mjs", "do_back")
fn do_back(_steps: Int) -> Nil {
  Nil
}
