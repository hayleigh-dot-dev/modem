import { Some, None } from "../gleam_stdlib/gleam/option.mjs";
import { Uri, to_string } from "../gleam_stdlib/gleam/uri.mjs";

// CONSTANTS -------------------------------------------------------------------

const defaults = {
  handle_external_links: false,
  handle_internal_links: true,
};

// EXPORTS ---------------------------------------------------------------------

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
};

export const do_push = (uri) => {
  window.history.pushState({}, "", to_string(uri));
  window.requestAnimationFrame(() => {
    if (uri.fragment[0]) {
      document.getElementById(uri.fragment[0])?.scrollIntoView();
    }
  });
};

export const do_replace = (uri) => {
  window.history.replaceState({}, "", to_string(uri));
  window.requestAnimationFrame(() => {
    if (uri.fragment[0]) {
      document.getElementById(uri.fragment[0])?.scrollIntoView();
    }
  });
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
  if (el.tagName === "BODY") {
    return null;
  } else if (el.tagName === "A") {
    return el;
  } else {
    return find_anchor(el.parentElement);
  }
};

const uri_from_url = (url) => {
  return new Uri(
    /* scheme   */ new (url.protocol ? Some : None)(url.protocol),
    /* userinfo */ new None(),
    /* host     */ new (url.host ? Some : None)(url.host),
    /* port     */ new (url.port ? Some : None)(url.port),
    /* path     */ url.pathname,
    /* query    */ new (url.search ? Some : None)(url.search),
    /* fragment */ new (url.hash ? Some : None)(url.hash.slice(1)),
  );
};
