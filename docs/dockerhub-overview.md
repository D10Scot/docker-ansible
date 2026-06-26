# d10scot/ansible

**A batteries-included Ansible control node you can actually trust.** Hardened,
multi-arch (amd64 + arm64), and rebuilt every week across Alpine, Debian, and Ubuntu.

Pick a flavor, pull, and run. Every image runs non-root, ships as a lean multi-stage
runtime, and comes signed with an SBOM and build provenance — so you get a smooth
developer experience *and* a supply chain you can verify.

## Quick start

```bash
docker run --rm d10scot/ansible:latest ansible --version
```

Run a playbook — the image is **non-root (uid 1000)** with `WORKDIR /ansible`:

```bash
docker run --rm \
  -v "$PWD:/ansible" \
  -v ~/.ssh/id_ed25519:/home/ansible/.ssh/id_ed25519:ro \
  d10scot/ansible:latest \
  ansible-playbook -i inventory.yml playbooks/site.yml
```

## Choose your image

**Flavors**

- **`core`** — `ansible-core` only. Smallest and fastest.
- **`full`** — adds the community `ansible` meta-package. Batteries included.
- **`lint`** — `full` plus `ansible-lint`, ready for CI.

**Tags**

- `<flavor>-<distro>` — rolling, rebuilt weekly with the latest OS patches
  (e.g. `full-alpine`, `core-debian`, `lint-ubuntu`).
- `<corever>-<flavor>-<distro>` — pinned to an `ansible-core` minor when you want a
  stable target (e.g. `2.21-core-debian`).
- `latest` — alias for `full-alpine`.

👉 See the **Tags** tab above for the full, current list.

| Distro | Version | Architectures |
|---|---|---|
| Alpine | 3.22 | amd64 · arm64 |
| Debian | 13 (trixie) | amd64 · arm64 |
| Ubuntu | 24.04 LTS | amd64 · arm64 |

## Why you'll like it

- 🛡️ **Non-root** by default (uid 1000)
- 🪶 **Lean runtime** — multi-stage build, no compilers or dev headers shipped
- 📌 **Reproducible** — digest-pinned base images + fully hash-pinned Python deps (`pip install --require-hashes`)
- 🔄 **Always fresh** — rebuilt weekly with the latest OS security patches
- 🔍 **Scanned every build** — Trivy, Grype, pip-audit, and OSV-Scanner
- ✍️ **Signed & attested** — cosign signatures, SBOM (SPDX), and SLSA build provenance
- 🔗 **Tamper-evident pipeline** — every GitHub Action pinned by commit SHA

## Verify it yourself

Don't take our word for it — every image is cryptographically verifiable. The
signatures, SBOMs, and provenance attestations live on **GitHub Container Registry**
(`ghcr.io/d10scot/ansible`), which exposes them via the OCI Referrers API, so they're
discoverable straight from the image digest:

```bash
IMAGE=ghcr.io/d10scot/ansible:full-alpine
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/D10Scot/docker-ansible/\.github/workflows/build\.yml@refs/.*$' \
  "$IMAGE"
```

The full walkthrough — signature, SLSA provenance, SBOM, and verifying by digest — lives
in the GitHub repo: **[docs/verify.md](https://github.com/D10Scot/docker-ansible/blob/main/docs/verify.md)**.

*Pull from Docker Hub for convenience; verify against GHCR for assurance (Docker Hub
doesn't serve the attestations).*

## Links

- 📦 **Source & docs** — <https://github.com/D10Scot/docker-ansible>
- 🐙 **GHCR** (canonical, with attestations) — <https://github.com/D10Scot/docker-ansible/pkgs/container/ansible>
- 🐛 **Issues** — <https://github.com/D10Scot/docker-ansible/issues>
- 📄 **License** — MIT
