# Verifying this image

All images are signed with cosign keyless signing and carry SBOM (SPDX) and SLSA
build-provenance attestations. The canonical attestation registry is
`ghcr.io/d10scot/ansible` — Docker Hub (`docker.io/d10scot/ansible`) is a best-effort
mirror and does **not** expose the OCI Referrers API required for attestation lookup.
Always verify against GHCR, even if you pull from Docker Hub.

## Prerequisites

- [`cosign`](https://docs.sigstore.dev/cosign/system_config/installation/) ≥ 2.0
- [`gh`](https://cli.github.com/) ≥ 2.49 (for `gh attestation verify`)

## Copy-paste commands

```bash
IMAGE=ghcr.io/d10scot/ansible:full-alpine

# 1. Signature (keyless) — identity pinned to our publish workflow
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/D10Scot/docker-ansible/\.github/workflows/build\.yml@refs/.*$' \
  "$IMAGE"

# 2. SLSA build provenance
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible

# 3. SBOM attestation
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible --predicate-type https://spdx.dev/Document/v2.3

# 4. Everything attached (signatures, SBOMs, attestations)
cosign tree "$IMAGE"
```

Substitute `full-alpine` for any other tag (e.g. `core-debian`, `lint-ubuntu`,
`2.21.1-full-alpine`).

## What the checks prove

| Check | What it proves |
|---|---|
| `cosign verify` | The image was signed by our GitHub Actions publish workflow via Sigstore's Fulcio CA; the signing event is recorded in the public Rekor transparency log |
| `gh attestation verify` (provenance) | The image was built from a specific commit in this repository, by this specific workflow |
| `gh attestation verify` (SBOM) | An SBOM was attached at publish time by the same workflow |
| `cosign tree` | Shows all objects (signatures, attestations) attached to the image digest in the registry |

## Verifying an immutable tag by digest

For maximum assurance, resolve the tag to a digest first and verify against the digest:

```bash
DIGEST=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' ghcr.io/d10scot/ansible:full-alpine)
IMAGE="ghcr.io/d10scot/ansible@${DIGEST}"

cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/D10Scot/docker-ansible/\.github/workflows/build\.yml@refs/.*$' \
  "$IMAGE"
```

## Note on Docker Hub

If you pull from `docker.io/d10scot/ansible`, run verification against the equivalent
GHCR reference. Docker Hub does not implement the OCI 1.1 Referrers API, so
`cosign verify docker.io/d10scot/ansible:full-alpine` will not find the attached
signature.
