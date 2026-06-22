# Supply-chain security

This page explains what controls are in place to protect you from a compromised build,
a tampered image, or a malicious dependency — and _why_ each control matters.

---

## 1. GitHub Actions SHA-pinned

Every `uses:` reference in our workflows is pinned to an immutable commit SHA, not a
mutable tag like `@v4`.

**Why it matters:** In 2023 the `tj-actions/changed-files` action was compromised — its
`v35` tag was silently re-pointed to malicious code that exfiltrated CI secrets. Any
workflow using `uses: tj-actions/changed-files@v35` ran the attacker's code with no
visible change to the workflow file. SHA-pinning makes that attack impossible: the SHA
is cryptographically bound to a specific tree of code and cannot be re-pointed.

Renovate keeps the pins fresh and groups the SHA-bump PRs so they stay reviewable.
Actions are excluded from automerge (14-day minimum release age + manual approval).

---

## 2. Base images pinned by digest + OS patches applied at build

`FROM alpine:3.22@sha256:…` and equivalent Debian/Ubuntu lines ensure we always build
from the exact image we reviewed — a tag bump cannot silently swap in a different layer.

At the same time, `RUN apk upgrade --no-cache` (Alpine) / `apt-get upgrade` (Debian,
Ubuntu) runs _at build time_, so every new image ships with all OS security patches
available on that day, even between base-image tag releases.

**Why both?** Digest-pinning alone means you keep pulling an old, unpatched base forever.
`upgrade` alone without pinning means an upstream base-image tag could change under you.
Together they give you a reproducible build that is also patched.

---

## 3. Python dependencies fully hash-pinned

All Python packages (Ansible, ansible-lint, and their transitive deps) are installed
from lockfiles (`requirements/*.txt`) generated with
`uv pip compile --generate-hashes --python-platform` (one lockfile per
distro × flavor × arch = 18 total).
`pip install --require-hashes` enforces that _every_ package matches its recorded hash
before installation.

**Why it matters:** PyPI packages can be replaced or typosquatted. Hash-pinning means a
package substitution attack — even against a package you already depend on — is caught
before a single byte executes.

Renovate automerges patch and pin bumps for Python deps after the 7-day minimum release
age and green CI.

---

## 4. Vulnerability scanning gate — no publish credentials in scope

We run four independent scanners before any image is published:

| Scanner | What it checks |
|---|---|
| **Trivy** | OS packages + Python packages |
| **Grype** | OS packages + Python packages (independent DB) |
| **pip-audit** | Python packages (PyPI Advisory DB / OSV) |
| **OSV-Scanner** | All ecosystems via Google OSV |

The gate policy: **fixable CRITICAL OS CVEs** and **any Python vulnerability** block the
build. HIGH OS CVEs are uploaded to GitHub code scanning for visibility and trigger a
weekly rebuild.

**Critically, the scan jobs run with no registry push credentials in scope.** The
publish credentials are only injected in a separate `publish` job that runs _after_ all
scan jobs pass. This means that even if a scanner were itself compromised (e.g. via a
malicious Trivy DB), it could not push a backdoored image to the registry — it simply
doesn't have the keys.

Trivy's vulnerability DB is mirrored to our own GHCR (`ghcr.io/d10scot/trivy-db`) and
consumed with `--skip-db-update`, preventing a compromised upstream DB from being
substituted. **pip-audit and OSV-Scanner run as digest-pinned upstream containers**
(`python:3.13-slim@sha256:…` and `ghcr.io/google/osv-scanner@sha256:…`) — not from our
mirror — so they always pull from the respective canonical registries at their pinned
digest.

---

## 5. Cosign keyless signing

Every published image is signed with [Sigstore cosign](https://docs.sigstore.dev/) in
keyless mode. The signing certificate is issued by Sigstore's Fulcio CA and is tied to
the GitHub Actions OIDC identity of our publish workflow:

```
https://github.com/D10Scot/docker-ansible/.github/workflows/build.yml@refs/heads/main
```

The certificate and signature are recorded in the public Sigstore transparency log
(Rekor). Anyone can verify, without trusting us, that:

- the image was built by _our specific workflow file_
- in _our specific repository_
- and that this fact is recorded in a public, append-only log

**Contrast with typical community images:** most Docker Hub images carry no signature at
all. You have no way to know whether the image was built from the published Dockerfile,
or whether the tag was silently overwritten after the fact.

See [`docs/verify.md`](verify.md) for copy-paste verification commands.

---

## 6. SBOM (SPDX) attestation

A Software Bill of Materials in SPDX 2.3 format is attached to every image as an OCI
attestation. It lists every OS package and Python package present in the image, with
versions and checksums.

This lets you audit the exact bill of materials for any image you run, feed it into your
own vulnerability scanners, or satisfy supply-chain compliance requirements (e.g. US EO
14028, EU CRA).

---

## 7. SLSA Build Provenance (Level 2)

A [SLSA](https://slsa.dev/) build-provenance attestation is attached alongside the SBOM.
It records:

- which GitHub Actions workflow built the image
- the exact commit SHA of the source code
- the build inputs and environment

This lets you verify that the image you pull was actually produced from the source code
in this repository, and not assembled elsewhere and pushed.

---

## 8. GHCR as canonical attestation registry; Docker Hub as mirror

Attestations (signatures, SBOMs, provenance) are stored as OCI 1.1 Referrers objects on
`ghcr.io/d10scot/ansible`. Docker Hub does not implement the OCI Referrers API, so
attestations are **not available via `docker.io/d10scot/ansible`**.

Always verify against the GHCR canonical reference. See [`docs/verify.md`](verify.md).

---

## 9. Renovate with release-age cooldown

Renovate opens dependency-update PRs automatically, but with guardrails:

- **7-day minimum release age** for all packages — a package published in the last week
  is not yet updated. This gives the community time to catch and report a malicious
  package before it reaches our build.
- **14-day minimum** for GitHub Actions, which run with elevated CI permissions.
- Actions are **excluded from automerge** and always require human review.
- Base image digest bumps and Python patch releases **automerge** after cooldown + green
  CI, reducing toil for low-risk updates.

---

## Comparison with typical community images

| Control | This image | Typical community image |
|---|---|---|
| Base image pinned by digest | Yes | Rarely |
| OS patches applied at build | Yes | Sometimes |
| Python deps hash-pinned | Yes | No |
| Multi-scanner vuln gate | Yes | Rarely |
| Scan runs without push creds | Yes | N/A |
| Cosign signature | Yes | Rarely |
| SBOM attestation | Yes | Rarely |
| SLSA provenance | Yes | No |
| All Actions SHA-pinned | Yes | Rarely |
| Renovate with cooldown | Yes | Sometimes |
