# docker-ansible

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/D10Scot/docker-ansible/badge)](https://scorecard.dev/viewer/?uri=github.com/D10Scot/docker-ansible)
[![Signed with cosign](https://img.shields.io/badge/signed%20with-cosign-blue?logo=sigstore)](docs/verify.md)
[![SLSA Build L2](https://slsa.dev/images/gh-badge-level2.svg)](docs/supply-chain.md)
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

| Tag | Description |
|---|---|
| `latest` | Alias for `full-alpine` |
| `full-alpine` · `core-alpine` · `lint-alpine` | Rolling — rebuilt weekly with latest OS patches |
| `full-debian` · `core-debian` · `lint-debian` | Rolling — Debian trixie (13, Python 3.13) |
| `full-ubuntu` · `core-ubuntu` · `lint-ubuntu` | Rolling — latest Ubuntu LTS |
| `<corever>-full-alpine` · `<corever>-core-debian` · … | Immutable — e.g. `2.21.1-full-alpine` |

**Flavors:**
- `full` — `ansible` (all collections) + `ansible-lint`
- `core` — `ansible-core` only
- `lint` — `ansible-core` + `ansible-lint`

All tags are published to `ghcr.io/d10scot/ansible`, multi-arch (linux/amd64 +
linux/arm64), and are digest-pinnable and signed. See [Supply chain security](#supply-chain-security) below.

## Supply chain security

Every image is:

- Built from digest-pinned base images with OS packages upgraded at build time
- Scanned for vulnerabilities (Trivy, Grype, pip-audit, OSV-Scanner) before publish
- Signed with [cosign keyless signing](docs/verify.md) tied to our GitHub Actions workflow identity
- Accompanied by an **SBOM (SPDX)** and **SLSA build-provenance attestation**

See [`docs/supply-chain.md`](docs/supply-chain.md) for a full explanation of every
control and its rationale.

## Verifying this image

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

# 4. Everything attached
cosign tree "$IMAGE"
```

> **Note:** Verify against `ghcr.io/d10scot/ansible` — Docker Hub does not expose the
> OCI Referrers API needed to look up attestations.

See [`docs/verify.md`](docs/verify.md) for full details, including digest-based verification.
