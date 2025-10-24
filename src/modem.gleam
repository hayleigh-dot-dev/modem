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
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/uri.{type Uri, Uri}
import lustre
import lustre/dev/query.{type Query}
import lustre/dev/simulate.{type Simulation} as lustre_simulate
import lustre/effect.{type Effect}
import lustre/vdom/vattr.{Attribute}
import lustre/vdom/vnode.{Element}

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
    /// This option controls if you'd like to trigger your url change handler when
    /// a link to the same domain is clicked. When enabled, internal links will
    /// _always_ update the url shown in the browser's address bar but they _won't_
    /// trigger a page load. The `init` function enables this option when invoked.
    ///
    handle_internal_links: Bool,
    /// This option controls if you'd like to trigger your url change handler even
    /// when the link is to some external domain. You might want to do this for
    /// example to save some state in your app before the user navigates away.
    ///
    /// You will need to manually call [`load`](#load) to actually navigate to
    /// the external link!
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

//

/// Simulate a click on a link in the browser that would trigger a navigation.
/// This will dispatch a message to the simulated application if the link's `href`
/// is valid and would cause an internal navigation.
///
/// The base URL is necessary to resolve relative links. It should be a full
/// complete URL, typically the one you would use for the live version of your app.
/// For example:
///
/// - `https://lustre.build`
///
/// - `http://localhost:1234`
///
/// - `https://gleam.run/news`
///
/// Modem can simulate links that are relative to that base URL such as `./wibble`,
/// absolute paths like `/wobble`, or full URLs **as long as their origin matches
/// the base URL**.
///
/// External links will log a problem in the simulation's history. Links with an
/// empty `href` attribute will be ignored.
///
pub fn simulate(
  simulation: Simulation(model, msg),
  link query: Query,
  base route: String,
  on_url_change handler: fn(Uri) -> msg,
) -> Simulation(model, msg) {
  result.unwrap_both({
    use base <- result.try(result.replace_error(
      uri.parse(route),
      lustre_simulate.problem(
        simulation,
        "ModemInvalidBaseURL",
        "`" <> route <> "` is not a valid base URL",
      ),
    ))

    use origin <- result.try(result.replace_error(
      uri.origin(base),
      lustre_simulate.problem(
        simulation,
        "ModemInvalidBaseURL",
        "`" <> route <> "` is not a valid base URL",
      ),
    ))

    // The following is a sequence of crimes that should *never* be performed in
    // a real application. Introspecting the vdom is not supported by Lustre and
    // is liable to break at any time: relying on internals exempts you from semver!
    //
    // If you need to do this for some reason, please open an issue on the Lustre
    // repo so we can learn about your user case:
    //
    //   https://github.com/lustre-labs/lustre/issues/new
    //
    use target <- result.try(result.replace_error(
      query.find(in: lustre_simulate.view(simulation), matching: query),
      lustre_simulate.problem(
        simulation,
        name: "EventTargetNotFound",
        message: "No element matching " <> query.to_readable_string(query),
      ),
    ))

    use attributes <- result.try(case target {
      Element(tag: "a", attributes:, ..) -> Ok(attributes)
      _ ->
        Error(lustre_simulate.problem(
          simulation,
          name: "ModemInvalidTarget",
          message: "Target must be an <a> tag",
        ))
    })

    use href <- result.try(result.replace_error(
      list.find_map(attributes, fn(attribute) {
        case attribute {
          Attribute(name: "href", value:, ..) -> Ok(value)
          _ -> Error(Nil)
        }
      }),
      lustre_simulate.problem(
        simulation,
        name: "ModemMissingHref",
        message: "Target must have an `href` attribute",
      ),
    ))

    use relative <- result.try(result.replace_error(
      uri.parse(href),
      lustre_simulate.problem(
        simulation,
        name: "ModemInvalidHref",
        message: "`" <> href <> "` is not a valid URL",
      ),
    ))

    use _ <- result.try(case uri.origin(relative) {
      Ok(relative_origin) if origin != relative_origin ->
        Error(lustre_simulate.problem(
          simulation,
          name: "ModemExternalUrl",
          message: "`" <> href <> "` is an external URL and cannot be simulated",
        ))

      _ -> Ok(Nil)
    })

    use resolved <- result.try(result.replace_error(
      uri.merge(base, relative),
      lustre_simulate.problem(
        simulation,
        name: "ModemInvalidBaseURL",
        message: "`" <> route <> "` is not a valid base URL",
      ),
    ))

    Ok(lustre_simulate.message(simulation, handler(resolved)))
  })
}
