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
- `<major.minor>-<flavor>-<distro>` / `<core>-<flavor>-<distro>` — also rolling (rebuilt
  weekly), but they stay on one `ansible-core` minor or release (e.g. `X.Y-core-debian`,
  `X.Y.Z-core-debian`). Only the current `ansible-core` line is rebuilt; older `X.Y-*` /
  `X.Y.Z-*` tags stop moving once we move to a newer core.
- `<core>-<flavor>-<distro>-<YYYYMMDD>` — one build. Our pipeline creates it once and
  never re-points it (that is our policy; the registry does not enforce it), e.g.
  `X.Y.Z-core-debian-YYYYMMDD`.
- `@sha256:<digest>` — the strongest pin; signatures and attestations are bound to it.
- `latest` — alias for `full-alpine`.

👉 See the **Tags** tab above for the full, current list.

| Distro | Version | Architectures |
|---|---|---|
| Alpine | current stable | amd64 · arm64 |
| Debian | current stable | amd64 · arm64 |
| Ubuntu | current LTS | amd64 · arm64 |

The exact base image is pinned by digest in each `images/<distro>/Dockerfile`.

## Why you'll like it

- 🛡️ **Non-root** by default (uid 1000)
- 🪶 **Lean runtime** — multi-stage build, no compilers or dev headers shipped
- 📌 **Pinned inputs** — digest-pinned base images + fully hash-pinned Python deps (`pip install --require-hashes`)
- 🔄 **Always fresh** — rebuilt weekly with the latest OS security patches
- 🔍 **Scanned every build** — Trivy, Grype, pip-audit, and OSV-Scanner; fixable HIGH/CRITICAL findings block, and the digest that is scanned is the digest that ships
- ✍️ **Signed & attested** — cosign signatures, an SBOM (SPDX) per architecture, and SLSA build provenance
- 🔗 **Tamper-evident pipeline** — every GitHub Action pinned by commit SHA

## Verify it yourself

Don't take our word for it — every image is cryptographically verifiable. Our
pipeline pushes the signatures, SBOMs, and provenance attestations only to **GitHub
Container Registry** (`ghcr.io/d10scot/ansible`); the Docker Hub copy has the same
digest but nothing attached. Verify against GHCR:

```bash
IMAGE=ghcr.io/d10scot/ansible:full-alpine
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/publish.yml@refs/heads/main \
  "$IMAGE"
```

Images published before our reusable publish workflow first ran (until then, every
tag) are signed by `build.yml` instead: use
`--certificate-identity=https://github.com/D10Scot/docker-ansible/.github/workflows/build.yml@refs/heads/main`
for those.

The full walkthrough — signature, SLSA provenance, SBOM, verifying by digest, and
verifying a Docker Hub pull with `COSIGN_REPOSITORY` — lives in the GitHub repo:
**[docs/verify.md](https://github.com/D10Scot/docker-ansible/blob/main/docs/verify.md)**.

*Pull from Docker Hub for convenience; verify against GHCR for assurance (we sign and
attest only there).*

## Links

- 📦 **Source & docs** — <https://github.com/D10Scot/docker-ansible>
- 🐙 **GHCR** (canonical, with attestations) — <https://github.com/D10Scot/docker-ansible/pkgs/container/ansible>
- 🐛 **Issues** — <https://github.com/D10Scot/docker-ansible/issues>
- 📄 **License** — MIT
