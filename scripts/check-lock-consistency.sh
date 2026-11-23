#!/bin/sh
# Fail if any `name==version` pin in requirements/*.in differs from that package's
# pin in any matching requirements/<distro>-<flavor>-<arch>.txt lockfile.
#
# Renovate bumps the direct pins in the .in files; the lockfiles must then be
# regenerated (lock.yml). This check turns a bare .in bump into a red CI run
# (fail closed) until someone relocks. It also fails if a pinned package is absent
# from a lockfile, or if no lockfile matches an .in file.
#
# Usage: scripts/check-lock-consistency.sh [requirements-dir]
set -eu
dir=${1:-requirements}
errs=$(mktemp)
trap 'rm -f "$errs"' EXIT

for in_file in "$dir"/*.in; do
  flavor=$(basename "$in_file" .in)
  found=0
  for lock in "$dir"/*-"${flavor}"-*.txt; do
    [ -e "$lock" ] || continue
    found=1
    # Direct pins: `name==1.2.3`, optionally followed by a comment.
    pins=$(sed 's/[[:space:]]*#.*//' "$in_file" | grep -E '^[A-Za-z0-9][A-Za-z0-9._-]*==' || true)
    for pin in $pins; do
      name=${pin%%==*}
      want=${pin#*==}
      # Lockfile names are normalised (lowercase; `_` and `.` become `-`); compare that way.
      got=$(awk -v n="$name" '
        function norm(s) { s = tolower(s); gsub(/[_.]/, "-", s); return s }
        match($0, /^[A-Za-z0-9._-]+==[^ ]+/) {
          split(substr($0, 1, RLENGTH), a, "==")
          if (norm(a[1]) == norm(n)) { print a[2]; exit }
        }' "$lock")
      if [ "$got" != "$want" ]; then
        echo "MISMATCH: ${name}: ${in_file} pins ${want}, ${lock} has ${got:-<absent>}" >>"$errs"
      fi
    done
  done
  [ "$found" -eq 1 ] || echo "NO LOCKFILE matches ${in_file}" >>"$errs"
done

if [ -s "$errs" ]; then
  cat "$errs" >&2
  echo "lockfiles out of date: relock (gh workflow run lock.yml --ref <branch>), download the artifacts, commit." >&2
  exit 1
fi
echo "lock consistency OK"
