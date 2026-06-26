# docker-ansible

Hardened, multi-arch (amd64/arm64), multi-distro Ansible control-node images.

## ⚠️ Canonical registry: GHCR

`ghcr.io/d10scot/ansible` is the **source of truth**. This Docker Hub repo
(`d10scot/ansible`) is a best-effort convenience mirror.

GHCR supports the OCI 1.1 Referrers API, so cosign signatures, SBOMs, and SLSA
provenance attestations are natively discoverable there. Docker Hub does **not**
implement the Referrers API — `cosign verify` against a `docker.io` reference will not
find the attached signature. **Always verify against GHCR, by digest**, even if you run
the image from Docker Hub.

## Verify before you run

Prerequisites: [`cosign`](https://docs.sigstore.dev/cosign/system_config/installation/) ≥ 2.0,
[`gh`](https://cli.github.com/) ≥ 2.49.

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

For maximum assurance, resolve to a digest first and verify the digest, not a mutable tag:

```bash
DIGEST=$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' ghcr.io/d10scot/ansible:full-alpine)
IMAGE="ghcr.io/d10scot/ansible@${DIGEST}"

cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/D10Scot/docker-ansible/\.github/workflows/build\.yml@refs/.*$' \
  "$IMAGE"
```

Full details: [`docs/verify.md`](https://github.com/D10Scot/docker-ansible/blob/main/docs/verify.md).

## Quick start

```bash
docker run --rm d10scot/ansible:latest ansible --version
```

Mount a playbook directory and an SSH key. The image runs **non-root as uid 1000**,
with `WORKDIR /ansible`:

```bash
docker run --rm \
  -v "$PWD:/ansible" \
  -v ~/.ssh/id_ed25519:/home/ansible/.ssh/id_ed25519:ro \
  d10scot/ansible:latest \
  ansible-playbook -i inventory.yml playbooks/site.yml
```

## Tag scheme

- `<flavor>-<distro>` — rolling, rebuilt weekly with the latest OS patches, e.g.
  `full-alpine`, `core-debian`, `lint-ubuntu`.
- `<corever>-<flavor>-<distro>` — immutable, pinned to a specific `ansible-core`
  minor version, e.g. `2.21-core-debian`.
- `latest` — alias for `full-alpine`.

Flavors: `core` (`ansible-core` only), `full` (+ the community `ansible` meta-package),
`lint` (`full` + `ansible-lint`).

See the **Tags** tab above for the full, current list.

## Distros & arches

| Distro | Version | Arches |
|---|---|---|
| Alpine | 3.22 | linux/amd64, linux/arm64 |
| Debian | 13 (trixie) | linux/amd64, linux/arm64 |
| Ubuntu | 24.04 LTS | linux/amd64, linux/arm64 |

## Security posture

- Runs **non-root** (uid 1000)
- **Multi-stage builds** — no build toolchain (compilers, dev headers) in the runtime image
- Base images **digest-pinned**, with OS security upgrades applied at build time
- Python dependencies **fully hash-pinned** (`pip install --require-hashes`)
- Scanned pre-publish: **Trivy**, **Grype**, **pip-audit**, **OSV-Scanner**
- **cosign-signed** (keyless), with **SBOM (SPDX)** and **SLSA build provenance** attestations
- All GitHub Actions **SHA-pinned** (no mutable tags in the build pipeline)

## Links

- Source: <https://github.com/D10Scot/docker-ansible>
- GHCR package: <https://github.com/D10Scot/docker-ansible/pkgs/container/ansible>
- Issues: <https://github.com/D10Scot/docker-ansible/issues>
- License: MIT
