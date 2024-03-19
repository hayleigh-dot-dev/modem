//// > **modem**: a device that converts signals produced by one type of device
//// > (such as a computer) to a form compatible with another (such as a
//// > telephone). - [Merriam-Webster](https://www.merriam-webster.com/dictionary/modem)
////
//// Modem is a little library for Lustre that helps you manage navigation and
//// URLs in the browser. It converts url requests into messages that you can
//// handle in your app's update function.
////

// IMPORTS ---------------------------------------------------------------------

import gleam/uri.{type Uri}
import lustre/effect.{type Effect}

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

// EFFECTS ---------------------------------------------------------------------

/// Initialise a simple modem that intercepts internal links and sends them to
/// your update function through the provided handler.
///
pub fn init(handler: fn(Uri) -> msg) -> Effect(msg) {
  use dispatch <- effect.from
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
pub fn advanced(options: Options, handler: fn(Uri) -> msg) -> Effect(msg) {
  use dispatch <- effect.from
  use uri <- do_advanced(_, options)

  uri
  |> handler
  |> dispatch
}

@external(javascript, "./modem.ffi.mjs", "do_init")
fn do_advanced(_handler: fn(Uri) -> Nil, _options: Options) -> Nil {
  Nil
}

/// Push a new uri to the browser's history stack. If the uri has the same domain
/// and port as the current page, or the uri is relative, this will not trigger
/// a full page reload.
///
/// **Note**: if you push a new uri while the user has navigated using the back
/// or forward buttons, you will clear any forward history in the stack!
///
pub fn push(uri: Uri) -> Effect(msg) {
  use _ <- effect.from
  do_push(uri)
}

@external(javascript, "./modem.ffi.mjs", "do_push")
fn do_push(_uri: Uri) -> Nil {
  Nil
}

/// Replace the current uri in the browser's history stack. If the uri has the
/// same domain and port as the current page, or the uri is relative, this will
/// not trigger a full page reload.
///
pub fn replace(uri: Uri) -> Effect(msg) {
  use _ <- effect.from
  do_replace(uri)
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
pub fn load(uri: Uri) -> Effect(msg) {
  use _ <- effect.from
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
pub fn forward(steps: Int) -> Effect(msg) {
  use _ <- effect.from
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
pub fn back(steps: Int) -> Effect(msg) {
  use _ <- effect.from
  do_back(steps)
}

@external(javascript, "./modem.ffi.mjs", "do_back")
fn do_back(_steps: Int) -> Nil {
  Nil
}
