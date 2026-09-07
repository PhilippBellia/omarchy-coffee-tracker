import QtQuick
import Quickshell.Io

// String lookup for the tracker.
//
// Every user-facing string lives in locales/<code>.json as a flat key →
// text map. Adding a language means adding one file and one entry to
// `available` — no QML changes, which is the point: a translation should be
// a pull request anyone can read, not a patch to the widget.
//
// English is loaded unconditionally as the fallback, so a locale file that
// is incomplete or brand new degrades key by key rather than showing raw
// keys. A missing key falls through en.json first and only then shows
// itself, which is what makes a partial translation shippable.
//
// Placeholders are positional (%1, %2, %3) rather than concatenation,
// because word order is exactly the thing that does not survive a
// translation: "%1 mg over daily goal" and "%1 mg over the daily goal"
// happen to align, but "in body %1 mg · under %2 mg from %3" does not
// reorder the same way everywhere, and a template can be rewritten freely
// while a string built with + cannot.
//
// The files are read through FileView rather than XMLHttpRequest, which
// Qt disables for local files unless QML_XHR_ALLOW_FILE_READ is set —
// not something a plugin gets to demand of the session it runs in.
// blockLoading makes the read synchronous, so the first paint already has
// its strings and no label is ever briefly a raw key.
QtObject {
  id: root

  // Language codes with a locales/<code>.json next to this file. Every
  // entry here shows up in the panel's language picker.
  readonly property var available: ["en", "de"]

  readonly property string fallbackCode: "en"

  // "auto" follows the session locale; anything else is an explicit choice
  // the user made in the panel and is persisted in shell.json.
  property string language: "auto"

  // The session's language, reduced to the bare code: Qt hands back
  // "de_DE.UTF-8" or "en_GB", and the roster is keyed by "de" / "en".
  readonly property string systemCode: {
    var raw = String(Qt.locale().name || "")
    var code = raw.split(".")[0].split("_")[0].toLowerCase()
    return code.length > 0 ? code : fallbackCode
  }

  // What is actually rendered. An unknown or unavailable choice falls back
  // rather than leaving the panel empty.
  readonly property string resolved: {
    var wanted = language === "auto" ? systemCode : String(language).toLowerCase()
    return available.indexOf(wanted) >= 0 ? wanted : fallbackCode
  }

  // Loaded tables. Both are plain objects; reading them inside t() is what
  // makes every binding that calls t() re-evaluate on a language change.
  property var strings: ({})
  property var fallbackStrings: ({})

  readonly property string decimalSeparator: t("meta.decimalSeparator")

  // FileView wants a filesystem path, and the locale files sit next to this
  // component wherever the plugin was installed.
  function localePath(code) {
    var url = String(Qt.resolvedUrl("locales/" + code + ".json"))
    return url.indexOf("file://") === 0 ? url.substring(7) : url
  }

  readonly property FileView activeFile: FileView {
    path: root.localePath(root.resolved)
    blockLoading: true
    printErrors: false
    onLoaded: root.strings = root.parseTable(this)
    onLoadFailed: root.strings = ({})
  }

  readonly property FileView fallbackFile: FileView {
    path: root.localePath(root.fallbackCode)
    blockLoading: true
    printErrors: false
    onLoaded: root.fallbackStrings = root.parseTable(this)
    onLoadFailed: root.fallbackStrings = ({})
  }

  function parseTable(view) {
    try {
      return JSON.parse(view.text() || "{}")
    } catch (e) {
      return ({})
    }
  }

  function reload() {
    root.fallbackStrings = parseTable(fallbackFile)
    root.strings = parseTable(activeFile)
  }

  // The path binding settles first, so the reload runs against the file the
  // new language actually points at.
  onResolvedChanged: Qt.callLater(reload)

  Component.onCompleted: reload()

  // Name of a language in its own language, for the picker.
  function displayName(code) {
    if (code === resolved) return t("meta.name")
    return String(code).toUpperCase()
  }

  // key → text, with %1..%n replaced by the extra arguments in order.
  // Lookup order is active locale → English → the key itself, so a missing
  // string is visible in the UI without ever being an empty label.
  function t(key) {
    var text = strings[key]
    if (text === undefined) text = fallbackStrings[key]
    if (text === undefined) return key

    text = String(text)
    for (var i = 1; i < arguments.length; i++)
      text = text.split("%" + i).join(String(arguments[i]))
    return text
  }

  // Number with the active locale's decimal mark. QML's own toFixed always
  // produces a dot, and a German panel reading "12.5 mg/g" is the kind of
  // detail that makes a translation feel bolted on.
  function decimal(value, digits) {
    var text = Number(value).toFixed(digits === undefined ? 1 : digits)
    return decimalSeparator === "." ? text : text.split(".").join(decimalSeparator)
  }
}
