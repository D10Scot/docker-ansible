# Verifying this image

All images are signed with cosign keyless signing and carry SBOM (SPDX) and SLSA
build-provenance attestations. Signatures and attestations are pushed **only** to
`ghcr.io/d10scot/ansible`. Docker Hub (`docker.io/d10scot/ansible`) is a best-effort
mirror that carries the same digests but nothing attached to them, because the publish
pipeline signs and attests only on GHCR. Always verify against GHCR, even if you pull
from Docker Hub (see [Note on Docker Hub](#note-on-docker-hub)).

> **Until the first `publish.yml` run on `main`**, every published tag (including
> `latest`) is still a digest signed by `build.yml`. For those, use the identity in
> [Images published before the reusable workflow](#images-published-before-the-reusable-workflow).

## Signer identity

Images are built, scanned, signed and attested inside the reusable workflow
`.github/workflows/publish.yml`, called from `build.yml` on `main` only. For a
reusable workflow, the Sigstore certificate identity (SAN) is the *reusable*
workflow's ref, not the caller's:

```
https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main
```

Pin to this string exactly. A regexp that accepts any ref (`@refs/.*`) would also
accept a signature made from a feature branch or a tag, which is exactly what you
want to reject.

## Prerequisites

- [`cosign`](https://docs.sigstore.dev/cosign/system_config/installation/) ≥ 2.0
- [`gh`](https://cli.github.com/) ≥ 2.68 (for `gh attestation verify --source-ref`; tested with 2.103.3)

## Copy-paste commands

```bash
IMAGE=ghcr.io/d10scot/ansible:full-alpine

# 1. Signature (keyless): exact identity of our publish workflow on main
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main \
  "$IMAGE"

# 2. SLSA build provenance, signed by the reusable publish workflow, from main
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible \
  --signer-workflow D10Scot/docker-ansible/.github/workflows/publish.yml \
  --source-ref refs/heads/main --deny-self-hosted-runners

# 3. SBOM attestation (one per architecture is attested on the index; see below)
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible \
  --signer-workflow D10Scot/docker-ansible/.github/workflows/publish.yml \
  --source-ref refs/heads/main --deny-self-hosted-runners \
  --predicate-type https://spdx.dev/Document/v2.3

# 4. Everything attached (signatures, SBOMs, attestations)
cosign tree "$IMAGE"
```

`--signer-workflow` is required because the attestation is produced by a reusable
workflow (`gh attestation verify --help`); `--source-ref` pins it to `main`.

Substitute `full-alpine` for any other tag (e.g. `core-debian`, `lint-ubuntu`,
`X.Y-full-alpine`, `X.Y.Z-full-alpine-YYYYMMDD`).

**SBOM subjects.** The pipeline generates one SPDX SBOM per architecture, from that
architecture's platform manifest. Each one is attested against its own platform
manifest digest *and* against the multi-arch index digest. A tag resolves to the index,
so command 3 finds both the amd64 and the arm64 SBOM; verifying
`oci://ghcr.io/d10scot/ansible@<platform digest>` finds just that architecture's SBOM.
Build provenance is attested on the index digest. The cosign signature is recursive,
covering the index and each platform manifest.

## What the checks prove

| Check | What it proves |
|---|---|
| `cosign verify` | The image was signed by our reusable publish workflow, running on `main`, via Sigstore's Fulcio CA; the signing event is recorded in the public Rekor transparency log |
| `gh attestation verify` (provenance) | The image was built from a specific commit on `main` in this repository, by `publish.yml` on a GitHub-hosted runner |
| `gh attestation verify` (SBOM) | An SBOM for each architecture was attached at publish time by the same workflow |
| `cosign tree` | Shows all objects (signatures, attestations) attached to the image digest in the registry |

The digest that is signed and attested is the same digest that the pipeline scanned
(Trivy, Grype) and smoke-tested before any tag pointed at it. See
[`supply-chain.md`](supply-chain.md#4-vulnerability-scanning-gate-scan-the-digest-you-ship).

## Verifying by digest (strongest pin)

Rolling tags move. The dated `<core>-<flavor>-<distro>-<YYYYMMDD>` tags are not moved
by our pipeline, which creates each one once and skips it if it already exists. That is
our policy, though, not something the registry enforces. A digest cannot move: it is
content-addressed, and it is what the signature and attestations are bound to. Resolve
the tag once, then verify and run the digest:

```bash
DIGEST=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' ghcr.io/d10scot/ansible:full-alpine)
IMAGE="ghcr.io/d10scot/ansible@${DIGEST}"

cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main \
  "$IMAGE"

docker run --rm "$IMAGE" ansible --version
```

## Images published before the reusable workflow

Digests published before `publish.yml` existed were signed by `build.yml` directly.
Until the first `publish.yml` run on `main`, that includes every current tag. They
carry SLSA Build L2 provenance (not L3) and one amd64-only SBOM on the index. Verify
them with the `build.yml` identity:

```bash
IMAGE=ghcr.io/d10scot/ansible:full-alpine

cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/build.yml@refs/heads/main \
  "$IMAGE"

gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible \
  --signer-workflow D10Scot/docker-ansible/.github/workflows/build.yml \
  --source-ref refs/heads/main --deny-self-hosted-runners
```

## Note on Docker Hub

The publish pipeline signs and attests only on GHCR, so nothing is attached to the
Docker Hub copy, and `cosign verify docker.io/d10scot/ansible:…` reports
`no signatures found`. The digest is identical on both registries, because promotion
copies the same manifest. So either verify the equivalent GHCR reference, or point
cosign at GHCR for the signature while naming the Docker Hub image by digest:

```bash
DIGEST=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' docker.io/d10scot/ansible:full-alpine)

COSIGN_REPOSITORY=ghcr.io/d10scot/ansible cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main \
  "docker.io/d10scot/ansible@${DIGEST}"
```

This was checked on 2026-11-23 with cosign v3.1.4 against
`docker.io/d10scot/ansible@sha256:f345…a2cd` (today's `latest`), using the `build.yml`
identity because that digest predates `publish.yml`. Verification passed; without
`COSIGN_REPOSITORY` it failed with `no signatures found`.

`gh attestation verify` works on a Docker Hub reference unchanged
(`gh attestation verify oci://docker.io/d10scot/ansible:full-alpine -R D10Scot/docker-ansible …`).
By default it looks attestations up by digest in GitHub's attestation API, not in the
registry. This was checked on 2026-11-23 against `docker.io/d10scot/ansible:latest`
(exit 0, with the `build.yml` signer).
