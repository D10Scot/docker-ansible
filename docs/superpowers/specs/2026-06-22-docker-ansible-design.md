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

- Immutable: `‹corever›-‹flavor›-‹distro›` where corever is major.minor — e.g.
  `2.21-full-alpine`, `2.21-core-debian`, `2.21-lint-ubuntu`.
- Floating: `‹flavor›-‹distro›` (e.g. `full-alpine`, `core-debian`) and `latest`
  (= `full-alpine`).
- Every tag is digest-pinnable; the README publicises pinning by digest.

## Repository layout

```
images/
  alpine/Dockerfile          # multi-stage, non-root, ARG-driven flavor
  debian/Dockerfile
  ubuntu/Dockerfile
requirements/
  core.in  full.in  lint.in            # top-level pins per flavor
  <distro>-<flavor>-<arch>.txt         # fully-resolved, hash-pinned lockfiles (18 total; committed)
.github/workflows/
  build.yml        # PR + main: build + scan gate; publish job (main only) signs + attests + tags
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

- **Base pinned by digest** (`FROM debian:trixie@sha256:…`), Renovate-maintained.
- **Multi-stage.** Builder stage installs compilers/headers and creates a venv at
  `/opt/ansible` via `pip install --require-hashes -r <lockfile>`. Final stage copies
  only the venv → no compilers or `-dev` headers in the runtime image.
- **Non-root by default.** `USER ansible` (uid 1000) with a writable home for
  `known_hosts`/SSH artifacts; documented `--user 0` escape hatch. No `sudo`. No
  PEP-668 `EXTERNALLY-MANAGED` deletion — we own a venv, we do not pollute system
  Python.
- `WORKDIR /ansible`; OCI labels: `org.opencontainers.image.source`, `.licenses`,
  `.title`. No `HEALTHCHECK` — this is a CLI image; smoke-test is `CMD ["ansible", "--version"]`.

## Python hash-pinning (primary control)

- `requirements/<flavor>.in` declares top-level pins: `ansible-core`, `ansible`,
  `ansible-lint`, `mitogen`, `jmespath`, `pywinrm`, `cryptography`, etc.
- `lock.yml` runs `uv pip compile --generate-hashes --python-platform` **inside each
  base image** (Python minor versions and arch differ per distro) and commits
  fully-resolved, hashed `requirements/<distro>-<flavor>-<arch>.txt` lockfiles
  (18 total: 3 distros × 3 flavors × 2 arches).
- Dockerfiles install with `pip install --require-hashes` so a single unhashed line
  is a hard error. This closes the "swap the artifact under a pinned version" window;
  SCA scanning (below) covers typosquats / known-bad releases it cannot.

## CI — scan-before-publish, with credential isolation

The pipeline **never pushes unscanned content to a public registry.** Images are
built to local OCI archives, scanned there, and only the exact scanned bytes are
published on pass. This designs away the "transient unscanned digest" problem
entirely — there is nothing to garbage-collect, and we avoid the GHCR footgun where a
naive "delete untagged digests" job would delete cosign signatures and SBOM/provenance
attestations (which are themselves stored as untagged referrer manifests).

1. **`build`** (PR + main). buildx + QEMU; matrix distro×flavor×arch
   (`linux/amd64`, `linux/arm64`). Each build outputs to a **docker-archive**
   (`--output type=docker,dest=…`) — nothing reaches the public registry. Scanners read
   image filesystems, not execute them, so an arm64 archive scans fine on an amd64
   runner.
2. **`scan`** (no registry write, no `id-token`; publish secrets absent from scope).
   Runs against the local archives:
   - **Grype** — OS/distro package layers (Alpine SecDB, Debian/Ubuntu feeds) + Python.
   - **Trivy** — `vuln` mode only (OS + Python packages). Vulnerability DB mirrored into
     our own GHCR (`ghcr.io/d10scot/trivy-db`) and consumed with `--skip-db-update`.
   - **pip-audit** — Python deps from each per-arch lockfile; runs as a digest-pinned
     upstream container (`python:3.13-slim@sha256:…`).
   - **OSV-Scanner** — independent OSV.dev matcher; runs as a digest-pinned upstream
     container (`ghcr.io/google/osv-scanner@sha256:…`).
   - Gate policy: block on fixable CRITICAL (OS) + any Python vulnerability; report HIGH
     to GitHub code scanning.
3. **`publish`** (main only; `needs: build-scan`; integrated into `build.yml` as a gated
   job). Rebuilds multi-arch from identical pinned inputs (reproducible from the same
   lockfiles + pinned base) and pushes directly to GHCR + Docker Hub. Then: cosign
   keyless `--recursive` sign by index digest (OIDC `id-token`); generate the SBOM with
   **syft** and provenance via `actions/attest-build-provenance` + `actions/attest-sbom`
   (`push-to-registry: true`) against the final digest; apply human-facing tags via
   `docker/metadata-action`; sync README → Docker Hub.

**Invariants:** no unscanned digest is ever published or signed; scanners never run in
a job holding publish credentials, so a poisoned scanner has nothing to exfiltrate.

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

- **No transient unscanned digests** by design — the scan-before-publish flow never
  pushes unscanned content. We deliberately avoid a "delete untagged digests" GC step:
  on GHCR, signatures and SBOM/provenance attestations are stored as untagged referrer
  manifests, so such a job would silently delete them and break verification.
- **Docker Hub attestation discoverability** is inherently weaker (no Referrers API);
  accepted, with verification steered to GHCR.
- **Trivy inclusion** reintroduces a tool with a recent compromise; mitigated by
  SHA-pinning to a known-good release and mirroring its DB. Revisit if Trivy's posture
  regresses — the other three scanners stand alone if it is dropped.
- Lockfile regeneration must run inside each base image; `uv` has known rough edges
  refreshing hashes in place — `lock.yml` regenerates from scratch to avoid that.

---

## Implementation deviations (recorded 2026-06-22)

These differ from the design above; all were forced by reality during bring-up and verified green in CI:

1. **Debian base bookworm(12) → trixie(13).** `ansible-core 2.21` requires Python ≥3.12; Debian 12 ships 3.11. Trixie ships 3.13. This keeps all three distros on the same current ansible (14.0.0 / core 2.21.1 / lint 26.4.0), which also fixes `CVE-2025-14010` (ansible <12.2.0).
2. **Per-arch lockfiles (18), not 9 + `--universal`.** `uv ... --universal` is unsatisfiable because `ansible-lint` pulls a yanked win32-only sentinel; resolving per `--python-platform` (amd64/arm64) inside each base image avoids it and is arch-correct. Dockerfiles select by `TARGETARCH`. `setuptools` is pinned in the lockfiles (Debian's venv shipped a CVE-affected 66.x).
3. **Scanners as digest-pinned containers where the action was unusable.** OSV-Scanner and pip-audit run as pinned containers (`ghcr.io/google/osv-scanner@sha256:…`, `python:3.13-slim@sha256:…`) rather than marketplace actions; lockfile scanners run on the per-arch lockfile, image scanners (Trivy/Grype) on the docker-archive.
4. **Vuln-gate policy: block on fixable CRITICAL (OS) + ANY python vuln; report HIGH→code scanning.** Strict HIGH gating on OS packages is unwinnable while a distro's fix is in-flight (e.g. util-linux CVE-2026-536xx "fixed per tracker, not yet released"). The python layer we fully control is gated strictly. Weekly rebuild absorbs OS fixes as they land.
5. **Publish integrated into `build.yml` as a `publish` job** (gated `needs: build-scan`, non-PR) rather than a separate `release.yml`, which guarantees scan-before-publish in one workflow. Images are rebuilt multi-arch from identical pinned inputs (reproducible), pushed, cosign-signed, and SBOM+provenance-attested.
6. **Trivy image scan = `vuln` only.** Secret scanning flagged example creds in bundled ansible-collection source (false positives) → gitleaks covers our secrets; hadolint covers Dockerfile misconfig.

**Verified (2026-06-22):** `cosign verify` (identity-pinned to the publish workflow, Rekor-logged), `gh attestation verify` for SLSA provenance (`https://slsa.dev/provenance/v1`) and SBOM (`https://spdx.dev/Document/v2.3`) all pass against `ghcr.io/d10scot/ansible`.

**Outstanding manual/operator steps:** add `DOCKERHUB_TOKEN` secret + `DOCKERHUB_USERNAME` var to activate the Docker Hub mirror; optional zizmor self-hardening (template-injection via env, persist-credentials:false) on our own workflows.
