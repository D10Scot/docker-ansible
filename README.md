# docker-ansible

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/D10Scot/docker-ansible/badge)](https://scorecard.dev/viewer/?uri=github.com/D10Scot/docker-ansible)
[![Signed with cosign](https://img.shields.io/badge/signed%20with-cosign-blue?logo=sigstore)](docs/verify.md)
[![SLSA Build L3](https://slsa.dev/images/gh-badge-level3.svg)](docs/supply-chain.md#7-slsa-build-provenance-level-3)
[![Build](https://github.com/D10Scot/docker-ansible/actions/workflows/build.yml/badge.svg)](https://github.com/D10Scot/docker-ansible/actions/workflows/build.yml)

Supply-chain-hardened, multi-distro (Alpine/Debian/Ubuntu), multi-arch (amd64/arm64)
Ansible container images. Canonical registry: `ghcr.io/d10scot/ansible`.
Docker Hub (`docker.io/d10scot/ansible`) is a best-effort mirror.

## Usage

```bash
docker run --rm -v "$PWD:/ansible" ghcr.io/d10scot/ansible:full-alpine \
  ansible-playbook -i inventory.yml playbooks/site.yml
```

## Tags

| Tag | Moves? | Description |
|---|---|---|
| `latest` | Rolling | Alias for `full-alpine` |
| `<flavor>-<distro>` | Rolling | e.g. `full-alpine`, `core-debian`, `lint-ubuntu`; rebuilt weekly with the latest OS patches |
| `<major.minor>-<flavor>-<distro>` | Rolling | Tracks an `ansible-core` minor line, e.g. `2.21-full-alpine` |
| `<core>-<flavor>-<distro>` | Rolling | Tracks an exact `ansible-core` release, e.g. `2.21.6-full-alpine`; still rebuilt weekly for OS patches |
| `<core>-<flavor>-<distro>-<YYYYMMDD>` | **Never** | One build, e.g. `2.21.6-full-alpine-20261123`; created once, never overwritten, never patched |
| `@sha256:<digest>` | **Never** | The strongest pin: content-addressed, and what signatures and attestations are bound to |

Distros: Alpine 3.22, Debian trixie (13, Python 3.13), Ubuntu 24.04 LTS.

Pin by digest (or the dated tag) for reproducibility; follow a rolling tag to get the
weekly OS patches. Resolve a tag to its digest with
`docker buildx imagetools inspect --format '{{.Manifest.Digest}}' ghcr.io/d10scot/ansible:full-alpine`.

**Flavors:**
- `core` — `ansible-core` only
- `full` — `ansible` (the community meta-package, i.e. ansible-core + all bundled collections)
- `lint` — `full` + `ansible-lint`

All tags are published to `ghcr.io/d10scot/ansible`, multi-arch (linux/amd64 +
linux/arm64), and are digest-pinnable and signed. See [Supply chain security](#supply-chain-security) below.

## Supply chain security

Every image is:

- Built from digest-pinned base images with OS packages upgraded at build time
- Scanned for vulnerabilities (Trivy, Grype, pip-audit, OSV-Scanner) before publish;
  fixable HIGH/CRITICAL findings block. The digest that is scanned is the digest that
  is tagged and signed. Nothing is rebuilt after the scan.
- Signed with [cosign keyless signing](docs/verify.md) tied to our GitHub Actions workflow identity
- Accompanied by an **SBOM (SPDX)** and **SLSA build-provenance attestation**

See [`docs/supply-chain.md`](docs/supply-chain.md) for a full explanation of every
control and its rationale.

## Verifying this image

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

# 4. Everything attached
cosign tree "$IMAGE"
```

> **Note:** Verify against `ghcr.io/d10scot/ansible` — Docker Hub does not expose the
> OCI Referrers API needed to look up attestations.

See [`docs/verify.md`](docs/verify.md) for full details, including digest-based verification.
