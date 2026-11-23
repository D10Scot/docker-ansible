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

Each Dockerfile's `FROM <distro>:<version>@sha256:…` line ensures we always build
from the exact image we reviewed — a tag bump cannot silently swap in a different layer.

At the same time, `RUN apk upgrade --no-cache` (Alpine) / `apt-get upgrade` (Debian,
Ubuntu) runs _at build time_, so every new image ships with all OS security patches
available on that day, even between base-image tag releases.

**Why both?** Digest-pinning alone means you keep pulling an old, unpatched base forever.
`upgrade` alone without pinning means an upstream base-image tag could change under you.
Together they give you a known starting point that is also patched.

**What this is not:** a reproducible build. `apk upgrade` / `apt-get upgrade` pull
from live distro mirrors, so two builds of the same commit can differ. We do not rely
on rebuilding: the pipeline builds each image **once**, scans that exact digest, and
then tags and signs that same digest (see §4). The scheduled weekly rebuild is what
picks up new OS patches when nothing in the repository has changed.

---

## 3. Python dependencies fully hash-pinned

All Python packages (Ansible, ansible-lint, and their transitive deps) are installed
from lockfiles (`requirements/*.txt`) generated with
`uv pip compile --upgrade --generate-hashes --python-platform --exclude-newer "7 days"`
(see `scripts/lock.sh`; one lockfile per distro × flavor × arch = 18 total), run inside
the digest-pinned base image with a digest-pinned `uv`. `--exclude-newer` applies the
7-day release-age cooldown to transitive dependencies too, not just direct ones.
`pip install --require-hashes` enforces that _every_ package matches its recorded hash
before installation.

**Why it matters:** PyPI packages can be replaced or typosquatted. Hash-pinning means a
package substitution attack — even against a package you already depend on — is caught
before a single byte executes.

Python dependency updates are **not** automerged. Renovate bumps the direct pins in
`requirements/*.in` after the 7-day minimum release age. A lock-consistency CI check
then fails until someone regenerates the hash-pinned lockfiles
(`gh workflow run lock.yml --ref <branch>`), downloads the artifacts and commits them,
so every lockfile change is reviewed.

---

## 4. Vulnerability scanning gate: scan the digest you ship

We run four independent scanners:

| Scanner | What it checks |
|---|---|
| **Trivy** | OS packages + Python packages |
| **Grype** | OS packages + Python packages (independent DB) |
| **pip-audit** | Python packages (PyPI Advisory DB / OSV) |
| **OSV-Scanner** | All ecosystems via Google OSV |

**Gate policy:** any **fixable HIGH or CRITICAL** finding from Trivy or Grype blocks,
and so does **any** known vulnerability that pip-audit or OSV-Scanner reports in the
Python lockfile. Findings with no fix released yet (`ignore-unfixed` / `only-fixed`) are
not gated, because there is nothing to upgrade to. When a fix lands, the next build
(at the latest the weekly scheduled one) either picks it up or fails.

**Exceptions** live in two reviewed files, and nowhere else:

- `.trivyignore.yaml`: Trivy's YAML ignore format, with `statement` and `expired_at`.
  It is passed to every Trivy step through the action's `trivyignores` input, which
  sets `TRIVY_IGNOREFILE`.
- `.grype.yaml`: Grype's config file, with `reason` and `expires`. It is loaded with
  `GRYPE_CONFIG`.

`scripts/check-ignore-expiry.sh` runs in CI on every event, including the weekly
schedule. It parses both files with a real YAML parser (a digest-pinned `yq`
container), so quoted keys, flow style and anchors are resolved by YAML rules, not by
line patterns. It fails on any entry that is expired, has no expiry, has no reason or has no
CVE/ID. It also fails on any top-level key outside a small allowlist: for Grype only
`ignore` is allowed, so a setting like `exclude` or `only-fixed` cannot weaken the gate
outside review. Duplicate keys and multiple YAML documents fail as well, and so does any
stray config file the scanners would load on their own (`trivy.yaml`, `.grype/`, …). Trivy
also stops honouring an entry after `expired_at`. Grype has no expiry field of its own
and ignores the `expires` key, so for Grype the script is the only enforcement. Both
files are empty today.

**The pipeline, per image variant** (`.github/workflows/publish.yml`, run only on `main`):

1. **stage:** build multi-arch **once** and push to GHCR **by digest, untagged**. This
   job holds only `packages: write`. QEMU (`tonistiigi/binfmt`) and BuildKit
   (`moby/buildkit`) run from digest-pinned images.
2. **verify:** a separate job with a **read-only** token (no `packages: write`, no
   `id-token`). For each architecture, on a native runner, it scans that exact digest
   with the Trivy and Grype gates above. It then smoke-tests it: `ansible --version`
   must report the locked ansible-core version, the image must run as uid 1000, and
   the architecture must match.
3. **sbom:** a separate, minimal job (`packages: read` only; no checkout, no scanner,
   no third-party action except `actions/upload-artifact`). It runs a digest-pinned
   `syft` container on each architecture's platform manifest, with an anonymous pull,
   checks that each SPDX document describes that manifest digest, and uploads each
   file unarchived. It reports both the scanned digests and each artifact's sha256
   as job outputs. It is kept apart from `verify` so that no scanner can modify an
   SBOM that is later attested.
4. **promote:** only after verify and sbom pass, and only if this run's commit is
   still `main`'s HEAD (checked with the GitHub API, failing closed). Without that
   check, re-running an old run could move the rolling tags back to an older build.
   It cosign-signs the index digest (recursively), attests build provenance on it,
   and attests the SBOMs after the checks below. Only then does it point the tags at
   that **same digest** with `docker buildx imagetools create`, on GHCR and (when
   configured) Docker Hub, and assert that every tag resolves to it. This is the only
   job with `id-token`, `attestations` or signing rights. It runs **no scanner and no
   SBOM generator**, and checks out no repository code. What does run with those
   credentials is the Docker login and buildx actions, cosign (downloaded by
   `sigstore/cosign-installer`), the attest and artifact actions, `gh api` and
   `docker buildx imagetools`.

**SBOM trust chain** (checked in `promote` before any SBOM is attested):

1. `actions/download-artifact` (v8.0.2, `digest-mismatch: error`) hashes the bytes it
   downloads and fails if they differ from the digest GitHub recorded at upload.
2. Each file's `sha256sum` must equal the `artifact-digest` that the `sbom` job itself
   reported as a job output. With `archive: false`, that digest is the hash of the
   file's own bytes, so like is compared with like. This catches an artifact replaced
   by any other job in the run, because only the `sbom` job can set its outputs.
3. The per-arch digests the `sbom` job scanned must equal the platform manifests of
   the index that `verify` passed, re-resolved from the registry in `promote`.
4. Each SBOM's SPDX root package (the document's single `DESCRIBES` target) must carry
   that exact manifest digest as its `versionInfo` and SHA256 checksum.

Each per-arch SBOM is then attested against its own platform manifest digest *and*
against the index digest. A tag resolves to the index, so verifying a tag finds an
SBOM for every architecture.

A PR-time matrix (`build-scan` in `build.yml`) runs the same Trivy and Grype gates plus
pip-audit and OSV-Scanner on local archives with **no push credentials**, as early
feedback. Publishing also requires it to pass.

**Why it matters:** no scanner and no SBOM generator, even a compromised one, runs in
a job that can push, sign or attest, and a scanner cannot alter an SBOM before it is
attested. The bytes that are tagged and signed are the bytes that were scanned, not a
later rebuild that pulled different packages from a live mirror.

**Trivy DB provenance:** Trivy's vulnerability DBs are mirrored weekly
(`trivy-db-mirror.yml`, Monday 03:00 UTC) into our own GHCR (`ghcr.io/d10scot/trivy-db:2`,
`ghcr.io/d10scot/trivy-java-db:1`). Every Trivy step points at the mirror with the
`TRIVY_DB_REPOSITORY` and `TRIVY_JAVA_DB_REPOSITORY` environment variables, so Trivy
downloads its DB from our registry rather than from upstream at scan time. We do
**not** use `--skip-db-update`; the mirror is the control. The trade-off is that the
DB can be up to a week old (see [`known-defects.md`](known-defects.md)). Grype
downloads its own DB from Anchore at scan time. **pip-audit and OSV-Scanner run as
digest-pinned upstream containers** (`python:3.13-slim@sha256:…` and
`ghcr.io/google/osv-scanner@sha256:…`) and query their upstream advisory sources
directly.

---

## 5. Cosign keyless signing

Every published image is signed with [Sigstore cosign](https://docs.sigstore.dev/) in
keyless mode. The signing certificate is issued by Sigstore's Fulcio CA and is tied to
the GitHub Actions OIDC identity of our publish workflow. Signing happens inside the
reusable workflow `publish.yml`, so the identity is that workflow's ref on `main`:

```
https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main
```

Verify against that exact string, not a pattern that accepts any ref.

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

A Software Bill of Materials in SPDX 2.3 format is generated **per architecture** by a
digest-pinned `syft`, from that architecture's platform manifest. It is attested on
that manifest and on the multi-arch index (see the trust chain in §4). It lists every OS
package and Python package present in the image, with versions and checksums.
Digests published before `publish.yml` carry one SBOM on the index that describes only
amd64.

This lets you audit the exact bill of materials for any image you run, feed it into your
own vulnerability scanners, or satisfy supply-chain compliance requirements (e.g. US EO
14028, EU CRA).

---

## 7. SLSA Build Provenance (Level 3)

A [SLSA](https://slsa.dev/) build-provenance attestation is attached alongside the SBOM.
It records:

- which GitHub Actions workflow built the image
- the exact commit SHA of the source code
- the build inputs and environment

This lets you verify that the image you pull was actually produced from the source code
in this repository, and not assembled elsewhere and pushed.

**Why Level 3.** GitHub documents two levels for its artifact attestations:

- "Artifact attestations by itself provides SLSA v1.0 Build Level 2."
- "Reusable workflows can provide isolation between the build process and the calling
  workflow, to meet SLSA v1.0 Build Level 3."

(GitHub Docs, [Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations),
and [Using artifact attestations and reusable workflows to achieve SLSA v1 Build Level 3](https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-and-reusable-workflows-to-achieve-slsa-v1-build-level-3).)

Our build, scan, signing and attestation all run inside the reusable workflow
`publish.yml`, on GitHub-hosted ephemeral runners. The caller (`build.yml`) can
influence it only through two allowlisted inputs, `distro` and `flavor`. Signing
credentials (`id-token`) exist only in the `promote` job, which runs on a separate
runner from the build and runs no repository code. Consumers verify the reusable
workflow as the signer with `gh attestation verify --signer-workflow` (see
[`verify.md`](verify.md)), which is how GitHub's guide says to check this level.

Caveats, stated plainly:

- **Same repository.** The reusable workflow lives in the same repository as its
  caller, so anyone who can change `build.yml` on `main` can also change `publish.yml`.
  GitHub's guide covers same-repository reusable workflows (`--signer-repo` is only
  needed when they differ). The isolation is between workflow runs and between the
  build and the signing material; protection of `main` itself still rests on branch
  protection and review.
- **Only digests from `publish.yml` are L3.** Digests published before it existed
  were attested by `build.yml` directly and are L2.

---

## 8. GHCR as canonical attestation registry; Docker Hub as mirror

The pipeline pushes signatures, SBOMs and provenance **only** to
`ghcr.io/d10scot/ansible`. The cosign signature is a `sha256-<digest>.sig` tag; the
attestations are OCI 1.1 referrers. `promote` copies just the image manifest to Docker
Hub, so the Docker Hub copy has the same digest but nothing attached. To verify a Docker
Hub pull, either use the GHCR reference with the same digest, or set
`COSIGN_REPOSITORY=ghcr.io/d10scot/ansible` for cosign. `gh attestation verify` works on
either reference, because it looks attestations up by digest in GitHub's API. See
[`docs/verify.md`](verify.md#note-on-docker-hub).

---

## 9. Renovate with release-age cooldown

Renovate opens dependency-update PRs automatically, but with guardrails:

- **7-day minimum release age** for all packages — a package published in the last week
  is not yet updated. This gives the community time to catch and report a malicious
  package before it reaches our build.
- **14-day minimum** for GitHub Actions, which run with elevated CI permissions.
- Actions are **excluded from automerge** and always require human review.
- Only **base-image digest** bumps (`alpine`, `debian`, `ubuntu`) automerge, via a PR,
  after the cooldown and green CI. Tool images (scanners, linters) and the Dockerfile
  frontend are updated manually.
- **Python dependencies are never automerged.** Renovate bumps `requirements/*.in`. The
  lockfiles are regenerated with `lock.yml` and committed by a person (see §3).
- Renovate also tracks the `image@sha256:` pins inside workflows and the pre-commit
  config, so those digests do not go stale silently.

**Status:** Renovate is configured (`renovate.json`) but not installed on the
repository yet; see [`known-defects.md`](known-defects.md).

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
| SLSA provenance (Build L3) | Yes | No |
| Scanned digest = shipped digest | Yes | Rarely |
| All Actions SHA-pinned | Yes | Rarely |
| Renovate with cooldown | Yes | Sometimes |
