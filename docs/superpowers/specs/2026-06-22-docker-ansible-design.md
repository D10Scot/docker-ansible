# Design: `D10Scot/docker-ansible` — a supply-chain-hardened Ansible image

**Date:** 2026-06-22
**Status:** Approved (design); implementation plan to follow

## Goal

Publish the most trustworthy multi-distro, multi-arch Ansible container image on
Docker Hub and GHCR. Where the popular incumbent (`willhallonline/ansible`) ships
unsigned images built from unpinned bases and unpinned pip dependencies, running as
root with no SBOM, provenance, signing, or scanning, this project does the opposite
and **publicises the difference** so consumers can verify it.

The project must not become a supply-chain victim itself. The March 2026 Trivy
compromise (CVE-2026-33634) and the 2025 tj-actions/reviewdog compromises all share
one root cause — **mutable action tags force-pushed to malicious commits**. Every
control below is designed against that class of attack.

## Non-goals

- Not a general-purpose Python image; payload is Ansible.
- Not chasing SLSA L4 (hermetic/reproducible). Target is SLSA Build **L2** via
  GitHub-native attestations, with a documented path to L3 if needed later.
- No cloud-backed scanners (Docker Scout, Snyk) — they require accounts and send
  image/dependency metadata to a vendor; wrong fit for a privacy/supply-chain-first
  OSS project.

## Distribution

- **GHCR `ghcr.io/d10scot/ansible`** is the canonical attestation home. GHCR
  implements the OCI 1.1 Referrers API, so signatures, SBOM and provenance
  attestations are natively discoverable and verifiable against a digest.
- **Docker Hub `d10scot/ansible`** is a reach mirror. Docker Hub does **not**
  implement the Referrers API; cosign/attestations fall back to the referrers
  *tag schema* (`sha256-<digest>.sig` / `.sbom`). Verification documentation
  therefore tells consumers to verify **by digest against GHCR**.
- Operator provides: a Docker Hub org `d10scot` + a scoped push **access token**
  (stored as the `DOCKERHUB_TOKEN` repo secret; username as a repo `var`).

### Build matrix

| Axis | Values |
|---|---|
| Distro (base, digest-pinned) | `alpine`, `debian`, `ubuntu` |
| Flavor | `core` (ansible-core), `full` (+ `ansible` community pkg), `lint` (full + `ansible-lint`) |
| Arch | `linux/amd64`, `linux/arm64` |

### Tag scheme

Anchored on the ansible-core version. Immutable, fully-qualified tags plus floating
convenience aliases:

- Immutable: `‹corever›-‹flavor›-‹distro›‹distrover›` — e.g. `2.18-full-debian12`,
  `2.18-core-alpine3.22`, `2.18-lint-ubuntu24.04`.
- Floating: `latest` (= `full` on alpine), `core`, `full`, `lint`, `‹distro›`.
- Every tag is digest-pinnable; the README publicises pinning by digest.

## Repository layout

```
images/
  alpine/Dockerfile          # multi-stage, non-root, ARG-driven flavor
  debian/Dockerfile
  ubuntu/Dockerfile
requirements/
  core.in  full.in  lint.in            # top-level pins per flavor
  <distro>-<flavor>.txt                # fully-resolved, hash-pinned lockfiles (committed)
.github/workflows/
  build.yml        # PR + main: build (by digest, no tags) + scan gate
  release.yml      # main/tags: sign + attest + tag + mirror (needs scan pass)
  lock.yml         # regenerate hash-pinned lockfiles inside each base image
  renovate.yml     # self-hosted Renovate, SHA-pinned
  scorecard.yml    # OpenSSF Scorecard -> badge
renovate.json
.pre-commit-config.yaml      # hadolint, actionlint, zizmor, gitleaks
README.md
SECURITY.md
docs/supply-chain.md         # transparency page
```

## Image build (per Dockerfile)

- **Base pinned by digest** (`FROM debian:12@sha256:…`), Renovate-maintained.
- **Multi-stage.** Builder stage installs compilers/headers and creates a venv at
  `/opt/ansible` via `pip install --require-hashes -r <lockfile>`. Final stage copies
  only the venv → no compilers or `-dev` headers in the runtime image.
- **Non-root by default.** `USER ansible` (uid 1000) with a writable home for
  `known_hosts`/SSH artifacts; documented `--user 0` escape hatch. No `sudo`. No
  PEP-668 `EXTERNALLY-MANAGED` deletion — we own a venv, we do not pollute system
  Python.
- `WORKDIR /ansible`; OCI labels (`org.opencontainers.image.source`, `.revision`,
  `.created`); a lightweight `HEALTHCHECK`/`CMD ["ansible", "--version"]` smoke.

## Python hash-pinning (primary control)

- `requirements/<flavor>.in` declares top-level pins: `ansible-core`, `ansible`,
  `ansible-lint`, `mitogen`, `jmespath`, `pywinrm`, `cryptography`, etc.
- `lock.yml` runs `uv pip compile --generate-hashes` **inside each base image**
  (Python minor versions differ per distro) and commits fully-resolved, hashed
  `requirements/<distro>-<flavor>.txt` lockfiles.
- Dockerfiles install with `pip install --require-hashes` so a single unhashed line
  is a hard error. This closes the "swap the artifact under a pinned version" window;
  SCA scanning (below) covers typosquats / known-bad releases it cannot.

## CI — three-stage gate with credential isolation

1. **`build`** (PR + main). buildx + QEMU; matrix distro×flavor; `linux/amd64,arm64`.
   Pushes **by digest only, no tags** to GHCR. Emits BuildKit SBOM (`sbom: true`)
   and SLSA provenance (`provenance: true, mode=max`).
2. **`scan`** (no registry write, no `id-token`; secrets absent from scope). Pulls by
   digest and runs:
   - **Grype** — OS/distro package layers (Alpine SecDB, Debian/Ubuntu feeds).
   - **Trivy** — added for IaC/secrets/license breadth. Pinned to known-good
     `v0.35.0` **by full commit SHA**; vulnerability DB **mirrored into our own GHCR**
     and consumed with `--skip-db-update` (no runtime fetch from upstream).
   - **OSV-Scanner** — independent OSV.dev matcher, run `--offline`.
   - **pip-audit** — Python deps from the lockfile (PyPA + OSV advisory DBs).
   - Results uploaded as SARIF → GitHub code scanning. Configurable severity gate.
3. **`sign-and-promote`** (main/tags only; runs only if `scan` passes). cosign keyless
   `--recursive` sign by digest (OIDC `id-token`); `actions/attest-build-provenance`
   + `actions/attest-sbom` with `push-to-registry: true`; **then** apply human-facing
   tags via `docker/metadata-action` and mirror to Docker Hub.

**Invariant:** unscanned digests are never tagged or signed. Scanners never run in a
job that holds publish credentials, so a poisoned scanner has nothing to exfiltrate.

## Supply-chain hardening (cross-cutting)

- 100% of GitHub Actions pinned by full 40-char commit SHA, version in a trailing
  comment; bases by digest; pip by hash.
- Per-job least-privilege `permissions:`; no `pull_request_target`; PRs cannot push or
  access publish secrets (fork-safe).
- **`zizmor`** lints our own workflows for these exact issues (unpinned actions,
  injection, excessive permissions) in pre-commit and CI; plus `actionlint`,
  `hadolint`, `gitleaks`.
- **OpenSSF Scorecard** workflow + badge.
- Tool installers (cosign, syft, grype, trivy, osv-scanner) consumed as SHA-pinned
  actions or digest-pinned containers — never `curl | sh`.

## Renovate

- Self-hosted as a **SHA-pinned action** under a scoped token (keeps the update bot
  inside our own pinned supply chain rather than trusting the always-latest hosted app).
- `pinDigests: true`; extends `helpers:pinGitHubActionDigestsToSemver` and
  `docker:pinDigests`.
- Cooldown via `minimumReleaseAge`: **7 days** for deps/base images, **14 days** for
  GitHub Actions; `internalChecksFilter: strict` (no branch/PR created until the
  cooldown elapses).
- **Automerge** (after cooldown + green CI) for **base-image digest** updates and
  **Python patch** lockfile bumps only.
- **GitHub Actions are excluded from automerge** — even after cooldown, an action
  SHA re-point requires human review. Auto-merging it is the exact tj-actions/Trivy
  vector; the cost of manual review is one click every few weeks.
- In-place `pinDigest` re-points on the workflows path are disabled; action SHAs move
  only when the SemVer comment changes (a real version bump).

## Publicising / verification (visibility requirement)

- README "Verifying this image" section with copy-paste commands:
  - `cosign verify --certificate-oidc-issuer=… --certificate-identity-regexp=… ghcr.io/d10scot/ansible@sha256:…`
  - `gh attestation verify oci://ghcr.io/d10scot/ansible@sha256:… -R D10Scot/docker-ansible`
  - SBOM check (`--predicate-type https://spdx.dev/Document/v2.3`) and
    scan-from-SBOM example.
- Badges: OpenSSF Scorecard, signed-with-cosign, SLSA Build L2, SBOM-available,
  build status.
- `docs/supply-chain.md` transparency page documenting the whole pipeline (the
  "why trust this" page) — explicitly contrasting with unpinned/unsigned alternatives.
- Real `SECURITY.md`: private disclosure via GitHub security advisories + a stated
  patch SLA and the weekly rebuild cadence.
- A step syncing README → Docker Hub description on release.

## Risks & open items

- **Transient unscanned digests** exist in GHCR between `build` and `sign-and-promote`.
  Mitigated by never tagging/signing them; optionally GC untagged digests on a schedule.
- **Docker Hub attestation discoverability** is inherently weaker (no Referrers API);
  accepted, with verification steered to GHCR.
- **Trivy inclusion** reintroduces a tool with a recent compromise; mitigated by
  SHA-pinning to a known-good release and mirroring its DB. Revisit if Trivy's posture
  regresses — the other three scanners stand alone if it is dropped.
- Lockfile regeneration must run inside each base image; `uv` has known rough edges
  refreshing hashes in place — `lock.yml` regenerates from scratch to avoid that.
