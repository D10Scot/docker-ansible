# Verifying this image

All images are signed with cosign keyless signing and carry SBOM (SPDX) and SLSA
build-provenance attestations. The canonical attestation registry is
`ghcr.io/d10scot/ansible`. Docker Hub (`docker.io/d10scot/ansible`) is a best-effort
mirror and does **not** expose the OCI Referrers API required for attestation lookup.
Always verify against GHCR, even if you pull from Docker Hub.

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
- [`gh`](https://cli.github.com/) ≥ 2.49 (for `gh attestation verify`)

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

# 3. SBOM attestation
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
`2.21-full-alpine`, `2.21.6-full-alpine-20261123`).

## What the checks prove

| Check | What it proves |
|---|---|
| `cosign verify` | The image was signed by our reusable publish workflow, running on `main`, via Sigstore's Fulcio CA; the signing event is recorded in the public Rekor transparency log |
| `gh attestation verify` (provenance) | The image was built from a specific commit on `main` in this repository, by `publish.yml` on a GitHub-hosted runner |
| `gh attestation verify` (SBOM) | An SBOM was attached at publish time by the same workflow |
| `cosign tree` | Shows all objects (signatures, attestations) attached to the image digest in the registry |

The digest that is signed and attested is the same digest that the pipeline scanned
(Trivy, Grype) and smoke-tested before any tag pointed at it. See
[`supply-chain.md`](supply-chain.md#4-vulnerability-scanning-gate-scan-the-digest-you-ship).

## Verifying by digest (strongest pin)

Tags other than the dated `<core>-<flavor>-<distro>-<YYYYMMDD>` tags move. A digest
never does, and it is what the signature and attestations are bound to. Resolve the
tag once, then verify and run the digest:

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

Digests published before `publish.yml` existed (up to and including the June 2026
builds) were signed by `build.yml` directly. To verify one of those, use
`--certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/build.yml@refs/heads/main`
for cosign, and `--signer-workflow D10Scot/docker-ansible/.github/workflows/build.yml`
for `gh attestation verify`. They carry SLSA Build L2 provenance, not L3.

## Note on Docker Hub

If you pull from `docker.io/d10scot/ansible`, run verification against the equivalent
GHCR reference: the digest is identical, because promotion copies the same manifest to
both registries. Docker Hub does not implement the OCI 1.1 Referrers API, so
`cosign verify docker.io/d10scot/ansible:full-alpine` will not find the attached
signature.
