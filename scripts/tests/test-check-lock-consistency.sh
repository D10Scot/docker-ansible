#!/bin/sh
# Tests for scripts/check-lock-consistency.sh. Builds throwaway fixture trees (images/ +
# requirements/) under a temp dir, runs the checker, and asserts exit status and that the
# message names the package and file. Run: sh scripts/tests/test-check-lock-consistency.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
checker="$here/../check-lock-consistency.sh"
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
pass=0
failn=0

# fresh <name>: a consistent fixture: 2 distros x flavors core+full x 2 arches.
fresh() {
  t="$root/$1"
  mkdir -p "$t/images/alpine" "$t/images/debian" "$t/requirements"
  printf '# core\nansible-core==2.21.6\njmespath\nsetuptools\n' >"$t/requirements/core.in"
  printf -- '-c core.in\nansible-core==2.21.6\nPyYAML==6.0.3\npip\n' >"$t/requirements/full.in"
  for d in alpine debian; do
    for a in amd64 arm64; do
      printf 'ansible-core==2.21.6 \\\n    --hash=sha256:aa\njmespath==1.0.1 \\\n    --hash=sha256:bb\nsetuptools==80.0.0 \\\n    --hash=sha256:cc\n' >"$t/requirements/$d-core-$a.txt"
      printf 'ansible-core==2.21.6 \\\n    --hash=sha256:aa\npyyaml==6.0.3 \\\n    --hash=sha256:dd\npip==26.3 \\\n    --hash=sha256:ee\n' >"$t/requirements/$d-full-$a.txt"
    done
  done
}

# run_case <fixture> <want-rc> <description> [grep-pattern ...]  (patterns must all appear)
run_case() {
  t="$root/$1"; want=$2; desc=$3; shift 3
  rc=0
  out=$(cd "$t" && sh "$checker" 2>&1) || rc=$?
  ok=1
  [ "$rc" -eq "$want" ] || ok=0
  for pat in "$@"; do
    printf '%s' "$out" | grep -Fq -- "$pat" || ok=0
  done
  if [ "$ok" -eq 1 ]; then
    pass=$((pass + 1)); echo "ok   - $desc"
  else
    failn=$((failn + 1)); echo "FAIL - $desc (rc=$rc, want $want)"; printf '%s\n' "$out" | sed 's/^/       | /'
  fi
}

fresh match
run_case match 0 "consistent tree passes"

fresh marker
printf 'cryptography==46.0.0 ; sys_platform == "linux"\n' >>"$root/marker/requirements/core.in"
for d in alpine debian; do for a in amd64 arm64; do
  printf 'cryptography==46.0.0 \\\n    --hash=sha256:ff\n' >>"$root/marker/requirements/$d-core-$a.txt"; done; done
run_case marker 0 "pin with '; marker' is compared on its version"

fresh mismatch
sed -i.bak 's/^PyYAML==6.0.3/PyYAML==6.0.4/' "$root/mismatch/requirements/full.in"
run_case mismatch 1 "version mismatch fails naming package and file" \
  "MISMATCH: PyYAML" "requirements/full.in" "debian-full-arm64.txt" "6.0.4"

fresh missingpkg
sed -i.bak '/^pyyaml/,+1d' "$root/missingpkg/requirements/debian-full-amd64.txt"
run_case missingpkg 1 "pinned package absent from a lockfile fails" \
  "MISSING PACKAGE: PyYAML" "debian-full-amd64.txt"

fresh missingfile
rm "$root/missingfile/requirements/alpine-core-arm64.txt"
run_case missingfile 1 "missing lockfile fails" "MISSING LOCKFILE" "alpine-core-arm64.txt"

fresh baremissing
sed -i.bak '/^setuptools/,+1d' "$root/baremissing/requirements/alpine-core-amd64.txt"
run_case baremissing 1 "bare name absent from a lockfile fails" \
  "MISSING PACKAGE: setuptools" "alpine-core-amd64.txt"

fresh extras
printf 'PyYAML[extra]==6.0.3\n' >>"$root/extras/requirements/full.in"
run_case extras 1 "name[extra]==v is rejected with file:line" "requirements/full.in:5:" "unsupported line"

fresh spaces
printf 'PyYAML == 6.0.3\n' >>"$root/spaces/requirements/full.in"
run_case spaces 1 "'name == v' is rejected with file:line" "requirements/full.in:5:" "unsupported line"

fresh indented
printf '  PyYAML==6.0.3\n' >>"$root/indented/requirements/full.in"
run_case indented 1 "indented pin is rejected with file:line" "requirements/full.in:5:" "unsupported line"

fresh operator
printf 'PyYAML>=6.0\n' >>"$root/operator/requirements/full.in"
run_case operator 1 "non-== operator is rejected" "requirements/full.in:5:"

fresh hyphen
printf 'ansible-core==2.21.6\n' >"$root/hyphen/requirements/full-x.in"
run_case hyphen 1 "flavor full-x is not satisfied by full lockfiles (no glob cross-match)" \
  "MISSING LOCKFILE" "alpine-full-x-amd64.txt"

fresh newdistro
mkdir "$root/newdistro/images/ubuntu"
run_case newdistro 1 "a distro dir under images/ requires its lockfiles" \
  "MISSING LOCKFILE" "ubuntu-core-amd64.txt"

echo "passed=$pass failed=$failn"
[ "$failn" -eq 0 ]
