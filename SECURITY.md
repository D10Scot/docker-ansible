# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please use GitHub's private disclosure mechanism instead:

1. Go to <https://github.com/D10Scot/docker-ansible/security/advisories>
2. Click **"Report a vulnerability"**
3. Fill in the details (affected tags, reproduction steps, potential impact)

We will acknowledge your report within **72 hours** and provide a best-effort fix as quickly as the severity warrants.

## Supported Tags

Rolling tags receive ongoing security maintenance through a weekly scheduled rebuild
(Mondays 05:00 UTC, plus every merge to `main` that touches the images) that refreshes
OS packages (`apk upgrade` / `apt-get upgrade`):

| Tag pattern | Moves? | Description |
|---|---|---|
| `latest` | Rolling | Alias for `full-alpine` |
| `<flavor>-<distro>` | Rolling | e.g. `full-alpine`, `core-debian`, `lint-ubuntu` |
| `<major.minor>-<flavor>-<distro>` | Rolling | Tracks an ansible-core minor, e.g. `X.Y-full-alpine` |
| `<core>-<flavor>-<distro>` | Rolling | Tracks an exact ansible-core release, e.g. `X.Y.Z-full-alpine`; still rebuilt weekly |
| `<core>-<flavor>-<distro>-<YYYYMMDD>` | Fixed by policy | One build, e.g. `X.Y.Z-full-alpine-YYYYMMDD`. The pipeline creates it once and skips it if it exists; the registry does not enforce this |
| `@sha256:<digest>` | **Immutable** | Strongest pin; content-addressed, and signatures and attestations are bound to it |

All published digests are signed with cosign keyless signing and carry SBOM and SLSA
build-provenance attestations. See [`docs/verify.md`](docs/verify.md) for verification
commands.

Dated tags and digests are not rebuilt, so they accumulate OS-level CVEs over time.
Only a digest is truly immutable. Follow a rolling tag if you want automatic patch coverage. If
you pin a dated tag or digest, you take responsibility for moving to a newer one.

## Weekly Rebuild Cadence

A scheduled CI run (`.github/workflows/build.yml`, `schedule`) rebuilds every variant
each week. Each build is scanned, and fixable HIGH or CRITICAL findings block it.
Only the exact digest that passed is tagged and signed. This picks up OS-level
security patches released upstream (Alpine, Debian, Ubuntu) even when the
Ansible versions have not changed.

If a weekly build is blocked (for example by a Python advisory that needs a lockfile
refresh), the rolling tags stay on the previous good digest until the finding is fixed.
Trivy and Grype findings can instead get a reviewed, time-limited exception in
`.trivyignore.yaml` / `.grype.yaml`. Known limitations of the pipeline are listed in
[`docs/known-defects.md`](docs/known-defects.md).
