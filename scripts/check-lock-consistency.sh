#!/bin/sh
# Fail closed unless every requirements/*.in is consistent with its lockfiles.
#
# Renovate bumps the direct `name==version` pins in the .in files; the lockfiles must then
# be regenerated (lock.yml). This check turns a bare .in bump into a red CI run until
# someone relocks.
#
# Rules:
#  - Every non-blank, non-comment, non-`-c <file>` line of an .in file must be exactly
#    `name==version` (optionally followed by `; marker`) or a bare `name`. Anything else
#    (extras `name[x]==v`, `name == v`, indented pins, other operators) is an error naming
#    file:line, because the comparison below could not see it.
#  - The expected lockfile set is exact: for every images/<distro>/ directory, every
#    <flavor>.in and arch in {amd64, arm64}: requirements/<distro>-<flavor>-<arch>.txt.
#    A missing file is an error. Globs are never used to find lockfiles.
#  - A `name==version` pin must equal that package's `==` pin in every lockfile (and the
#    package must be present). A bare name must be present in every lockfile.
#  - Names are compared normalised (lowercase; `_` and `.` become `-`).
#
# Usage: scripts/check-lock-consistency.sh [requirements-dir] [images-dir]
set -eu
dir=${1:-requirements}
images=${2:-images}
arches="amd64 arm64"

errs=$(mktemp)
pins=$(mktemp)
trap 'rm -f "$errs" "$pins"' EXIT

distros=""
for d in "$images"/*/; do
  [ -d "$d" ] || continue
  distros="$distros $(basename "$d")"
done
[ -n "$distros" ] || echo "no distros found under ${images}/" >>"$errs"

found_in=0
for in_file in "$dir"/*.in; do
  [ -e "$in_file" ] || continue
  found_in=1
  flavor=$(basename "$in_file" .in)

  # --- parse the .in file into "name want" (pinned) / "name" (bare) records ---
  : >"$pins"
  n=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    # blank or comment-only (leading whitespace allowed for these)
    if printf '%s' "$line" | grep -Eq '^[[:space:]]*(#.*)?$'; then continue; fi
    # constraint include
    if printf '%s' "$line" | grep -Eq '^-c[[:space:]]+[^[:space:]]+[[:space:]]*(#.*)?$'; then continue; fi
    body=$(printf '%s' "$line" | sed 's/[[:space:]][[:space:]]*#.*$//')
    if printf '%s' "$body" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*==[A-Za-z0-9][A-Za-z0-9._+!-]*([[:space:]]*;.*)?$'; then
      name=${body%%==*}
      rest=${body#*==}
      want=$(printf '%s' "$rest" | sed 's/[[:space:]]*;.*$//')
      printf '%s %s\n' "$name" "$want" >>"$pins"
    elif printf '%s' "$body" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$'; then
      printf '%s\n' "$body" >>"$pins"
    else
      echo "${in_file}:${n}: unsupported line (want 'name==version' or bare 'name'): ${line}" >>"$errs"
    fi
  done <"$in_file"

  # --- compare against the exact expected lockfile set ---
  for distro in $distros; do
    for arch in $arches; do
      lock="$dir/${distro}-${flavor}-${arch}.txt"
      if [ ! -f "$lock" ]; then
        echo "MISSING LOCKFILE: ${lock} (expected for ${in_file})" >>"$errs"
        continue
      fi
      while read -r name want; do
        [ -n "$name" ] || continue
        got=$(awk -v n="$name" '
          function norm(s) { s = tolower(s); gsub(/[_.]/, "-", s); return s }
          match($0, /^[A-Za-z0-9._-]+==[^ ]+/) {
            split(substr($0, 1, RLENGTH), a, "==")
            if (norm(a[1]) == norm(n)) { print a[2]; exit }
          }' "$lock")
        if [ -z "$got" ]; then
          echo "MISSING PACKAGE: ${name}: listed in ${in_file}, absent from ${lock}" >>"$errs"
        elif [ -n "$want" ] && [ "$got" != "$want" ]; then
          echo "MISMATCH: ${name}: ${in_file} pins ${want}, ${lock} has ${got}" >>"$errs"
        fi
      done <"$pins"
    done
  done
done
[ "$found_in" -eq 1 ] || echo "no .in files found in ${dir}/" >>"$errs"

if [ -s "$errs" ]; then
  cat "$errs" >&2
  echo "lockfiles inconsistent: relock (gh workflow run lock.yml --ref <branch>), download the artifacts, commit." >&2
  exit 1
fi
echo "lock consistency OK"
