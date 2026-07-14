/*
 * Toggle Texarkanine (default/slate) ↔ Rizzed (rizz/rizz-slate).
 * Button: overrides/partials/header.html (right of search).
 */
(() => {
  const KEY = "ai-rizz-theme-family"
  const BTN = ".ai-rizz-theme-family"
  const schemes = {
    texarkanine: { light: "default", dark: "slate" },
    rizz: { light: "rizz", dark: "rizz-slate" },
  }

  const family = () =>
    localStorage.getItem(KEY) === "rizz" ? "rizz" : "texarkanine"

  const scheme = () =>
    document.body.getAttribute("data-md-color-scheme") || "default"

  const isDark = (s) => s === "slate" || s === "rizz-slate"

  const sync = () => {
    const want = isDark(scheme())
      ? schemes[family()].dark
      : schemes[family()].light
    if (scheme() !== want)
      document.body.setAttribute("data-md-color-scheme", want)

    const on = family() === "rizz"
    const label = on
      ? "Color family: Rizzed (click for Texarkanine)"
      : "Color family: Texarkanine (click for Rizzed)"
    for (const btn of document.querySelectorAll(BTN)) {
      btn.ariaPressed = String(on)
      btn.title = btn.ariaLabel = label
    }
  }

  addEventListener("click", (e) => {
    if (!e.target.closest(BTN)) return
    localStorage.setItem(
      KEY,
      family() === "rizz" ? "texarkanine" : "rizz",
    )
    sync()
  })

  new MutationObserver(sync).observe(document.body, {
    attributes: true,
    attributeFilter: ["data-md-color-scheme"],
  })

  typeof document$ !== "undefined"
    ? document$.subscribe(sync)
    : addEventListener("DOMContentLoaded", sync)
})()
