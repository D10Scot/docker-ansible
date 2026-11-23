#!/bin/sh
# Compile per-arch, hash-pinned lockfiles for one distro.
#
# Runs INSIDE the digest-pinned base image (see .github/workflows/lock.yml) so the
# resolver targets that distro's Python version. Expects a `uv` binary on PATH
# (copied from a digest-pinned ghcr.io/astral-sh/uv image, never `curl | sh`).
#
# Usage: scripts/lock.sh <distro>
#
# - One lockfile per (distro, flavor, arch); --python-platform varies the arch.
#   No --universal: it pulls ansible-lint's yanked win32-only sentinel.
# - --exclude-newer applies the release-age cooldown to TRANSITIVE deps too,
#   matching Renovate's minimumReleaseAge for direct deps.
# - --upgrade: without it uv treats the existing -o file's pins as preferences,
#   so transitive deps (and their CVE fixes) silently never move.
set -eu
distro=${1:?usage: lock.sh <distro>}
cooldown=${LOCK_COOLDOWN:-7 days}

if command -v apk >/dev/null 2>&1; then
  apk add --no-cache python3 >/dev/null
else
  export DEBIAN_FRONTEND=noninteractive
  # Separate commands: under `set -e` a failure on the left of `&&` does NOT abort.
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends python3 >/dev/null
fi

# Resolve ONLY against the distro's own python3. Never let uv fetch a managed
# CPython: that is unpinned, and it would silently target the wrong Python version.
export UV_PYTHON_DOWNLOADS=never
py=$(command -v python3) || { echo "lock.sh: python3 not installed" >&2; exit 1; }
echo "lock.sh: resolving for $("$py" -V) on ${distro}" >&2

for pair in "amd64:x86_64-unknown-linux-gnu" "arm64:aarch64-unknown-linux-gnu"; do
  da=${pair%:*}; tri=${pair#*:}
  for f in core full lint; do
    uv pip compile --quiet --upgrade --python "$py" --python-platform "$tri" --generate-hashes \
      --exclude-newer "$cooldown" \
      "requirements/${f}.in" -o "requirements/${distro}-${f}-${da}.txt"
  done
done
