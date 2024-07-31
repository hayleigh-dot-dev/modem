import { Ok, Error } from "./gleam.mjs";
import { Some, None } from "../gleam_stdlib/gleam/option.mjs";
import { Uri, to_string } from "../gleam_stdlib/gleam/uri.mjs";

// CONSTANTS -------------------------------------------------------------------

const defaults = {
  handle_external_links: false,
  handle_internal_links: true,
};

const initial_location = window?.location?.href;

// EXPORTS ---------------------------------------------------------------------

export const do_initial_uri = () => {
  if (!initial_location) {
    return new Error(undefined);
  } else {
    return new Ok(uri_from_url(new URL(initial_location)));
  }
};

export const do_init = (dispatch, options = defaults) => {
  document.body.addEventListener("click", (event) => {
    const a = find_anchor(event.target);

    if (!a) return;

    try {
      const url = new URL(a.href);
      const uri = uri_from_url(url);
      const is_external = url.host !== window.location.host;

      if (!options.handle_external_links && is_external) return;
      if (!options.handle_internal_links && !is_external) return;

      event.preventDefault();

      if (!is_external) {
        window.history.pushState({}, "", a.href);
        window.requestAnimationFrame(() => {
          // The browser automatically attempts to scroll to an element with a matching
          // id if a hash is present in the URL. Because we need to `preventDefault`
          // the event to prevent navigation, we also need to manually scroll to the
          // element if a
          if (url.hash) {
            document.getElementById(url.hash.slice(1))?.scrollIntoView();
          }
        });
      }

      return dispatch(uri);
    } catch {
      return;
    }
  });

  window.addEventListener("popstate", (e) => {
    e.preventDefault();

    const url = new URL(window.location.href);
    const uri = uri_from_url(url);

    window.requestAnimationFrame(() => {
      if (url.hash) {
        document.getElementById(url.hash.slice(1))?.scrollIntoView();
      }
    });

    dispatch(uri);
  });

  window.addEventListener("modem-push", ({ detail }) => {
    dispatch(detail);
  });

  window.addEventListener("modem-replace", ({ detail }) => {
    dispatch(detail);
  });
};

export const do_push = (uri) => {
  window.history.pushState({}, "", to_string(uri));
  window.requestAnimationFrame(() => {
    if (uri.fragment[0]) {
      document.getElementById(uri.fragment[0])?.scrollIntoView();
    }
  });

  window.dispatchEvent(new CustomEvent("modem-push", { detail: uri }));
};

export const do_replace = (uri) => {
  window.history.replaceState({}, "", to_string(uri));
  window.requestAnimationFrame(() => {
    if (uri.fragment[0]) {
      document.getElementById(uri.fragment[0])?.scrollIntoView();
    }
  });

  window.dispatchEvent(new CustomEvent("modem-replace", { detail: uri }));
};

export const do_load = (uri) => {
  window.location = to_string(uri);
};

export const do_forward = (steps) => {
  if (steps < 1) return;

  for (let i = 0; i < steps; i++) {
    try {
      window.history.forward();
    } catch {
      continue;
    }
  }
};

export const do_back = (steps) => {
  if (steps < 1) return;

  for (let i = 0; i < steps; i++) {
    try {
      window.history.back();
    } catch {
      continue;
    }
  }
};

// UTILS -----------------------------------------------------------------------

const find_anchor = (el) => {
  if (!el || el.tagName === "BODY") {
    return null;
  } else if (el.tagName === "A") {
    return el;
  } else {
    return find_anchor(el.parentElement);
  }
};

const uri_from_url = (url) => {
  return new Uri(
    /* scheme   */ url.protocol
      ? new Some(url.protocol.slice(0, -1))
      : new None(),
    /* userinfo */ new None(),
    /* host     */ url.hostname ? new Some(url.hostname) : new None(),
    /* port     */ url.port ? new Some(Number(url.port)) : new None(),
    /* path     */ url.pathname,
    /* query    */ url.search ? new Some(url.search.slice(1)) : new None(),
    /* fragment */ url.hash ? new Some(url.hash.slice(1)) : new None(),
  );
};
