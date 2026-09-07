#!/usr/bin/env python3
"""Check the locale files against the strings the QML actually asks for.

Run it after editing a translation:

    python3 scripts/check-locales.py

It reports three things, and exits non-zero if any of them are wrong:

  * keys the QML looks up that en.json does not define — a broken lookup
    that shows a raw key in the panel
  * keys defined in en.json that nothing looks up — dead weight in every
    translation that follows
  * placeholders (%1, %2, ...) that a translation does not carry over from
    English — a sentence that silently drops a number

A translation is allowed to be incomplete: missing keys in a non-English
file fall back to English at runtime and are reported as a note, not an
error.
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCALES = os.path.join(ROOT, "locales")

# t("key"), t(cond ? "a" : "b"), and t("prefix." + expression)
DIRECT = re.compile(r'\bt\(\s*"([^"]+)"\s*[,)]')
TERNARY = re.compile(r'\bt\(\s*[A-Za-z0-9_.]+\s*\?\s*"([^"]+)"\s*:\s*"([^"]+)"')
PREFIX = re.compile(r'\bt\(\s*"([^"]+)"\s*\+')
PLACEHOLDER = re.compile(r"%\d")


def keys_used():
    """Keys the QML looks up, plus prefixes for keys it builds at runtime.

    A lookup like t("day.short." + date.getDay()) cannot be resolved
    statically, so its prefix is collected instead and every key starting
    with it counts as used.
    """
    used = set()
    prefixes = set()
    for name in sorted(os.listdir(ROOT)):
        if not name.endswith(".qml"):
            continue
        with open(os.path.join(ROOT, name), encoding="utf-8") as handle:
            src = handle.read()
        used |= set(DIRECT.findall(src))
        for pair in TERNARY.findall(src):
            used |= set(pair)
        prefixes |= set(PREFIX.findall(src))
    return used, prefixes


def load(code):
    with open(os.path.join(LOCALES, code + ".json"), encoding="utf-8") as handle:
        return json.load(handle)


def main():
    used, prefixes = keys_used()
    english = load("en")
    failed = False

    def is_used(key):
        return key in used or any(key.startswith(p) for p in prefixes)

    missing = sorted(k for k in used if k not in english)
    if missing:
        failed = True
        print("en.json is missing keys the QML looks up:")
        for key in missing:
            print("  " + key)

    unused = sorted(k for k in english if not is_used(k) and not k.startswith("meta."))
    if unused:
        failed = True
        print("en.json defines keys nothing looks up:")
        for key in unused:
            print("  " + key)

    for name in sorted(os.listdir(LOCALES)):
        if not name.endswith(".json") or name == "en.json":
            continue
        code = name[:-5]
        table = load(code)

        absent = sorted(k for k in english if k not in table)
        if absent:
            print("%s: %d of %d keys not translated yet, falling back to English"
                  % (code, len(absent), len(english)))

        extra = sorted(k for k in table if k not in english)
        if extra:
            failed = True
            print("%s: keys that do not exist in en.json:" % code)
            for key in extra:
                print("  " + key)

        for key, text in sorted(table.items()):
            if key not in english:
                continue
            wanted = set(PLACEHOLDER.findall(str(english[key])))
            got = set(PLACEHOLDER.findall(str(text)))
            if wanted != got:
                failed = True
                print("%s: %s expects %s, has %s"
                      % (code, key, sorted(wanted) or "no placeholders",
                         sorted(got) or "none"))

    if failed:
        return 1

    print("locales ok — %d keys, %d languages"
          % (len(english), len([n for n in os.listdir(LOCALES) if n.endswith(".json")])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
