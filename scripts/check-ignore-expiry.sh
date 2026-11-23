#!/usr/bin/env bash
# Fail if any vulnerability-ignore entry is expired, has no expiry, or has no reason.
#
# Policy (AGENTS.md, "Supply chain"): exceptions to the fixable HIGH/CRITICAL gate
# live in a reviewed ignore file, each with a reason and an expiry date, and CI
# fails on expired entries. Trivy honours `expired_at` itself; Grype has no expiry
# field at all and silently drops unknown keys, so this script is the only thing
# that enforces `expires` for Grype.
#
# Files checked (repo root):
#   .trivyignore.yaml  entries under any top-level section; needs `statement:` + `expired_at:`
#   .grype.yaml        entries under `ignore:`;              needs `reason:`    + `expires:`
#
# Dates must be plain ISO `YYYY-MM-DD`. An entry is expired when its date is on or
# before today (UTC). The parser is deliberately strict and line-based (no yq on
# every machine): block-style lists only; a non-empty flow list (`key: [x]`) or an
# unparseable date fails closed.
#
# Usage: scripts/check-ignore-expiry.sh [repo-root]
set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
today="$(date -u +%Y-%m-%d)"
status=0

# check FILE SECTIONS ID_KEYS REASON_KEY EXPIRY_KEY
#   SECTIONS: space-separated top-level keys whose list items are ignore entries.
#   ID_KEYS:  space-separated keys used to name an entry in messages.
check() {
  local file="$1" sections="$2" idkeys="$3" reasonkey="$4" expkey="$5"
  if [ ! -f "$file" ]; then
    echo "FAIL ${file}: file is missing" >&2
    return 1
  fi
  awk -v file="$file" -v today="$today" -v sections=" $sections " \
      -v idkeys=" $idkeys " -v reasonkey="$reasonkey" -v expkey="$expkey" '
    function indent(s) { match(s, /^ */); return RLENGTH }
    function unq(v) {
      sub(/^[ \t]+/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v)
      f = substr(v, 1, 1); l = substr(v, length(v), 1)
      if (length(v) >= 2 && f == l && (f == "\"" || f == "\047")) v = substr(v, 2, length(v) - 2)
      return v
    }
    function validdate(d,   y, m, dd) {
      if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
      y = substr(d, 1, 4) + 0; m = substr(d, 6, 2) + 0; dd = substr(d, 9, 2) + 0
      return (y >= 2000 && m >= 1 && m <= 12 && dd >= 1 && dd <= 31)
    }
    function flush() {
      if (!inentry) return
      name = (id != "" ? id : "(entry at line " startline ")")
      if (reason == "") {
        printf "FAIL %s:%d: %s has no %s\n", file, startline, name, reasonkey
        bad = 1
      }
      if (expd == "") {
        printf "FAIL %s:%d: %s has no %s\n", file, startline, name, expkey
        bad = 1
      } else if (!validdate(expd)) {
        printf "FAIL %s:%d: %s has unparseable %s \"%s\" (want YYYY-MM-DD)\n", file, startline, name, expkey, expd
        bad = 1
      } else if (expd <= today) {
        printf "FAIL %s:%d: %s expired on %s (today %s)\n", file, startline, name, expd, today
        bad = 1
      } else if (reason != "") {
        printf "ok   %s:%d: %s expires %s\n", file, startline, name, expd
      }
      n++
      inentry = 0
    }
    BEGIN { section = ""; itemindent = -1; bad = 0; n = 0 }
    /^[ \t]*#/ || /^[ \t]*$/ { next }
    /^[^ \t-]/ {                       # top-level key
      flush()
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:/, "", val); val = unq(val)
      section = (index(sections, " " key " ") ? key : "")
      itemindent = -1
      if (section != "" && val != "" && val != "[]") {
        printf "FAIL %s:%d: %s uses a flow list or scalar; use a block list\n", file, NR, key
        bad = 1
      }
      next
    }
    section == "" { next }
    {
      ind = indent($0)
      line = substr($0, ind + 1)
      if (line ~ /^- / || line == "-") {
        if (itemindent < 0) itemindent = ind
        if (ind == itemindent) {         # new entry
          flush()
          inentry = 1; startline = NR; id = ""; reason = ""; expd = ""
          line = substr(line, 3)
          if (line == "") next
        }
      }
      if (!inentry) next
      k = line; sub(/^- /, "", k)
      if (k !~ /^[A-Za-z_-]+:/) next
      v = k; sub(/^[^:]*:/, "", v); v = unq(v); sub(/:.*/, "", k)
      if (index(idkeys, " " k " ") && id == "") id = v
      if (k == reasonkey) reason = v
      if (k == expkey) expd = v
    }
    END {
      flush()
      printf "%s: %d entr%s checked\n", file, n, (n == 1 ? "y" : "ies")
      exit bad
    }
  ' "$file"
}

check "${root}/.trivyignore.yaml" "vulnerabilities misconfigurations secrets licenses" \
  "id" "statement" "expired_at" || status=1
check "${root}/.grype.yaml" "ignore" \
  "vulnerability" "reason" "expires" || status=1

if [ "$status" -ne 0 ]; then
  echo "Ignore-file policy violated: every entry needs a reason and a future expiry (YYYY-MM-DD)." >&2
fi
exit "$status"
