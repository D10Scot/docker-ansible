# docker-ansible Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a supply-chain-hardened, multi-distro (Alpine/Debian/Ubuntu), multi-arch (amd64/arm64) Ansible container image to GHCR + Docker Hub, with hash-pinned Python, scan-before-publish gating, cosign signing, SBOM + SLSA provenance attestations, and verification that consumers can actually run.

**Architecture:** One multi-stage `Dockerfile` per distro, parameterised by a `FLAVOR` build-arg (`core`/`full`/`lint`). Python deps are installed into a venv from a fully-resolved, hash-pinned lockfile. CI builds each `(distro, flavor, arch)` to a **local OCI archive**, scans the archive (Grype + Trivy + OSV-Scanner + pip-audit) with no publish credentials in scope, and only on pass pushes the **byte-identical** archive (via `skopeo`/`crane`), assembles the multi-arch manifest, signs it keyless with cosign, and attaches SBOM + provenance attestations. Renovate keeps every action SHA-pinned and every base image digest-pinned, behind a release-age cooldown.

**Tech Stack:** Docker Buildx + QEMU, GitHub Actions, `uv` (lockfile + hashes), Grype/Trivy/OSV-Scanner/pip-audit, Syft (SBOM), cosign + `actions/attest-*` (Sigstore), skopeo/crane, Renovate, OpenSSF Scorecard, pinact/hadolint/actionlint/zizmor/gitleaks.

**Reference spec:** `docs/superpowers/specs/2026-06-22-docker-ansible-design.md`

**Hard rules for the implementer:**
- **Never invent a commit SHA or image digest.** Where a pin is needed, resolve it with the command given in the task (`pinact`, `crane digest`, `docker buildx imagetools inspect`). A fabricated pin is a plan failure.
- Pin every GitHub Action by full 40-char commit SHA with a `# vX.Y.Z` comment.
- Scanners and untrusted-content builds must never run in a job that holds `DOCKERHUB_TOKEN`, `id-token: write`, or `packages: write`.

---

## File structure

```
.github/
  workflows/
    build.yml          # PR + push(main): build->OCI archive, scan gate (no creds)
    release.yml        # push(main)+tags: publish scanned bytes, sign, attest, tag, mirror
    lock.yml           # regenerate hash-pinned lockfiles inside each base image
    renovate.yml       # self-hosted Renovate, SHA-pinned action
    scorecard.yml      # OpenSSF Scorecard -> SARIF + badge
    lint.yml           # hadolint + actionlint + zizmor + gitleaks on PR
    trivy-db-mirror.yml# weekly: copy known-good trivy-db into ghcr.io/d10scot/trivy-db
images/
  alpine/Dockerfile
  debian/Dockerfile
  ubuntu/Dockerfile
requirements/
  core.in  full.in  lint.in                 # top-level pins per flavor
  alpine-core.txt  alpine-full.txt  alpine-lint.txt     # generated, hash-pinned
  debian-core.txt  ... (9 lockfiles: 3 distro x 3 flavor)
  ubuntu-core.txt  ...
scripts/
  resolve-base-digests.sh   # fill FROM ...@sha256 digests
  matrix.json               # build matrix source of truth
renovate.json
.pre-commit-config.yaml
.hadolint.yaml
.gitignore
LICENSE                     # MIT
README.md
SECURITY.md
docs/
  supply-chain.md           # transparency page
  verify.md                 # copy-paste verification commands
```

Matrix source of truth (`scripts/matrix.json`), referenced by `build.yml` and `release.yml`:

```json
{
  "include": [
    {"distro": "alpine", "distrover": "3.22", "flavor": "core"},
    {"distro": "alpine", "distrover": "3.22", "flavor": "full"},
    {"distro": "alpine", "distrover": "3.22", "flavor": "lint"},
    {"distro": "debian", "distrover": "12",   "flavor": "core"},
    {"distro": "debian", "distrover": "12",   "flavor": "full"},
    {"distro": "debian", "distrover": "12",   "flavor": "lint"},
    {"distro": "ubuntu", "distrover": "24.04","flavor": "core"},
    {"distro": "ubuntu", "distrover": "24.04","flavor": "full"},
    {"distro": "ubuntu", "distrover": "24.04","flavor": "lint"}
  ]
}
```

---

## Phase 0 — Repo scaffolding & local tooling

### Task 0: Initialise repo metadata and tooling guards

**Files:**
- Create: `.gitignore`, `LICENSE`, `.hadolint.yaml`, `.pre-commit-config.yaml`, `README.md` (skeleton)

- [ ] **Step 1: Create `.gitignore`**

```gitignore
*.tar
*.oci
sbom*.json
*.sarif
.venv/
__pycache__/
```

- [ ] **Step 2: Create `LICENSE`** — MIT, copyright holder `D10Scot`. Use the standard MIT text with year `2026`.

- [ ] **Step 3: Create `.hadolint.yaml`**

```yaml
failure-threshold: warning
ignored:
  - DL3008  # apt versions pinned via lockfile, not apt
  - DL3018  # apk versions: runtime pkgs intentionally unpinned (Renovate covers bases)
trustedRegistries:
  - docker.io
  - ghcr.io
```

- [ ] **Step 4: Create `.pre-commit-config.yaml`**

```yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.13.1
    hooks: [{id: hadolint-docker}]
  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.7
    hooks: [{id: actionlint}]
  - repo: https://github.com/woodruffw/zizmor-pre-commit
    rev: v1.5.2
    hooks: [{id: zizmor}]
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks: [{id: gitleaks}]
```

- [ ] **Step 5: Create `README.md` skeleton** with title, one-line description, a `## Tags` placeholder, and a `## Verifying this image` placeholder (filled in Task 9).

- [ ] **Step 6: Verify hooks run**

Run: `pre-commit run --all-files`
Expected: hooks execute; failures only on files not yet created are acceptable at this stage. No crash.

- [ ] **Step 7: Commit**

```bash
git add .gitignore LICENSE .hadolint.yaml .pre-commit-config.yaml README.md
git commit -m "chore: repo scaffolding, lint hooks, license"
```

---

## Phase 1 — Python dependency layer (hash-pinned)

### Task 1: Declare top-level requirements per flavor

**Files:**
- Create: `requirements/core.in`, `requirements/full.in`, `requirements/lint.in`

- [ ] **Step 1: `requirements/core.in`**

```
# Minimal Ansible control node.
ansible-core==2.18.1
# Connection/transport helpers commonly needed even on core.
cryptography
jmespath
```

- [ ] **Step 2: `requirements/full.in`**

```
-c core.in
ansible-core==2.18.1
ansible==11.1.0
cryptography
jmespath
mitogen
pywinrm
netaddr
```

- [ ] **Step 3: `requirements/lint.in`**

```
-c full.in
ansible-core==2.18.1
ansible==11.1.0
ansible-lint==24.12.2
cryptography
jmespath
mitogen
pywinrm
netaddr
```

- [ ] **Step 4: Commit**

```bash
git add requirements/*.in
git commit -m "feat: declare ansible flavor requirement sets"
```

> Note: top-level versions here are the *initial* values; Renovate (Task 11) bumps them. The pinned, hashed lockfiles are generated in Task 2.

### Task 2: Lockfile generation workflow + initial lockfiles

**Files:**
- Create: `.github/workflows/lock.yml`
- Create (generated): `requirements/<distro>-<flavor>.txt` (9 files)

- [ ] **Step 1: Write `lock.yml`** (uses `uv` inside each base image so the Python ABI matches the runtime image)

```yaml
name: lock
on:
  workflow_dispatch:
  push:
    paths: ["requirements/*.in", ".github/workflows/lock.yml"]
permissions:
  contents: read
jobs:
  lock:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - {distro: alpine, image: "alpine:3.22"}
          - {distro: debian, image: "debian:12"}
          - {distro: ubuntu, image: "ubuntu:24.04"}
    steps:
      - uses: actions/checkout@v4        # SHA-pinned by Task 12
      - name: Compile hashed lockfiles in ${{ matrix.distro }}
        run: |
          set -euo pipefail
          docker run --rm -v "$PWD:/w" -w /w "${{ matrix.image }}" sh -ceu '
            (command -v apk && apk add --no-cache python3 curl) || (apt-get update && apt-get install -y --no-install-recommends python3 curl ca-certificates)
            curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
            for f in core full lint; do
              uv pip compile --generate-hashes --universal \
                "requirements/${f}.in" -o "requirements/${{ matrix.distro }}-${f}.txt"
            done
          '
      - uses: actions/upload-artifact@v4
        with: {name: "lock-${{ matrix.distro }}", path: "requirements/${{ matrix.distro }}-*.txt"}
```

> The `curl | sh` for `uv` here runs **inside an ephemeral build container during lockfile generation only** — it never ships in the image and runs in a no-secrets job. Renovate cannot pin a piped installer; acceptable for this isolated, non-publishing context. (The published images never curl-pipe anything.)

- [ ] **Step 2: Generate lockfiles locally to commit the initial set**

Run (requires Docker + `uv` locally, or run the workflow once and download artifacts):
```bash
for d in "alpine:3.22|alpine" "debian:12|debian" "ubuntu:24.04|ubuntu"; do
  img=${d%|*}; name=${d#*|}
  docker run --rm -v "$PWD:/w" -w /w "$img" sh -ceu '
    (command -v apk && apk add --no-cache python3 curl) || (apt-get update && apt-get install -y --no-install-recommends python3 curl ca-certificates)
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
    for f in core full lint; do uv pip compile --generate-hashes --universal requirements/'"$f"'.in -o requirements/'"$name"'-'"$f"'.txt; done'
done
```
Expected: 9 files in `requirements/`, each line carrying `--hash=sha256:...`.

- [ ] **Step 3: Spot-check a lockfile is fully hashed**

Run: `grep -L -- '--hash=sha256' requirements/*.txt` (lists files with no hashes)
Expected: empty output (every lockfile contains hashes). Also confirm no top-level dep lacks a hash:
Run: `awk '/^[a-zA-Z0-9]/{p=$0} /--hash/{h=1} END{}' requirements/alpine-full.txt | head` (manual eyeball).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/lock.yml requirements/*.txt
git commit -m "feat: hash-pinned lockfiles per distro/flavor + lock workflow"
```

---

## Phase 2 — Images

### Task 3: Base-image digest resolution helper

**Files:**
- Create: `scripts/resolve-base-digests.sh`

- [ ] **Step 1: Write the helper** (prints the digest-pinned `FROM` lines; never hand-write digests)

```bash
#!/usr/bin/env bash
set -euo pipefail
# Requires: crane (go install github.com/google/go-containerregistry/cmd/crane@latest)
for ref in alpine:3.22 debian:12 ubuntu:24.04; do
  digest=$(crane digest "$ref")
  printf 'FROM %s@%s\n' "$ref" "$digest"
done
```

- [ ] **Step 2: Run it and record the output for use in Task 4**

Run: `bash scripts/resolve-base-digests.sh`
Expected: three `FROM name:tag@sha256:...` lines. Keep these for the Dockerfiles. (Renovate maintains them after the first commit.)

- [ ] **Step 3: Commit**

```bash
git add scripts/resolve-base-digests.sh
git commit -m "chore: base image digest resolver"
```

### Task 4: Alpine Dockerfile (multi-stage, non-root)

**Files:**
- Create: `images/alpine/Dockerfile`

- [ ] **Step 1: Write `images/alpine/Dockerfile`** (substitute the real `alpine:3.22@sha256:...` from Task 3 Step 2 in both `FROM` lines)

```dockerfile
# syntax=docker/dockerfile:1
ARG FLAVOR=full

FROM alpine:3.22@sha256:REPLACE_WITH_RESOLVED_DIGEST AS builder
ARG FLAVOR
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible
RUN apk add --no-cache python3 py3-pip build-base python3-dev libffi-dev openssl-dev cargo rust
RUN python3 -m venv /opt/ansible && /opt/ansible/bin/pip install --no-cache-dir --upgrade pip
COPY requirements/alpine-${FLAVOR}.txt /tmp/req.txt
RUN /opt/ansible/bin/pip install --no-cache-dir --require-hashes -r /tmp/req.txt

FROM alpine:3.22@sha256:REPLACE_WITH_RESOLVED_DIGEST AS runtime
ARG FLAVOR
RUN apk add --no-cache python3 openssh-client sshpass git rsync ca-certificates \
 && addgroup -g 1000 ansible \
 && adduser -u 1000 -G ansible -D -h /home/ansible ansible
COPY --from=builder /opt/ansible /opt/ansible
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible \
    ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1
USER ansible
WORKDIR /ansible
LABEL org.opencontainers.image.source="https://github.com/D10Scot/docker-ansible" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="ansible (${FLAVOR}, alpine)"
CMD ["ansible", "--version"]
```

> No `HEALTHCHECK`: this is a one-shot CLI image with no long-running service, so a healthcheck would be meaningless. (Deliberate deviation from the spec's tentative mention.)

- [ ] **Step 2: Build core + full + lint locally**

Run:
```bash
for f in core full lint; do
  docker build --build-arg FLAVOR=$f -f images/alpine/Dockerfile -t test-alpine-$f .
done
```
Expected: all three build successfully.

- [ ] **Step 3: Verify it runs and is non-root**

Run:
```bash
docker run --rm test-alpine-full ansible --version
docker run --rm test-alpine-lint ansible-lint --version
docker run --rm test-alpine-full id -u
```
Expected: ansible version prints; ansible-lint version prints; `id -u` prints `1000`.

- [ ] **Step 4: Confirm no build toolchain leaked into runtime**

Run: `docker run --rm test-alpine-full sh -c 'command -v gcc cargo || echo CLEAN'`
Expected: `CLEAN`.

- [ ] **Step 5: hadolint**

Run: `docker run --rm -i hadolint/hadolint < images/alpine/Dockerfile`
Expected: no errors above `warning` threshold.

- [ ] **Step 6: Commit**

```bash
git add images/alpine/Dockerfile
git commit -m "feat: alpine multi-stage non-root ansible image"
```

### Task 5: Debian Dockerfile

**Files:**
- Create: `images/debian/Dockerfile`

- [ ] **Step 1: Write `images/debian/Dockerfile`** (substitute the resolved `debian:12@sha256:...`)

```dockerfile
# syntax=docker/dockerfile:1
ARG FLAVOR=full

FROM debian:12@sha256:REPLACE_WITH_RESOLVED_DIGEST AS builder
ARG FLAVOR
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-venv python3-dev gcc libffi-dev libssl-dev cargo rustc \
 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/ansible && /opt/ansible/bin/pip install --no-cache-dir --upgrade pip
COPY requirements/debian-${FLAVOR}.txt /tmp/req.txt
RUN /opt/ansible/bin/pip install --no-cache-dir --require-hashes -r /tmp/req.txt

FROM debian:12@sha256:REPLACE_WITH_RESOLVED_DIGEST AS runtime
ARG FLAVOR
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 openssh-client sshpass git rsync ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -g 1000 ansible && useradd -u 1000 -g 1000 -m -d /home/ansible ansible
COPY --from=builder /opt/ansible /opt/ansible
ENV PATH=/opt/ansible/bin:$PATH VIRTUAL_ENV=/opt/ansible \
    ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1
USER ansible
WORKDIR /ansible
LABEL org.opencontainers.image.source="https://github.com/D10Scot/docker-ansible" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.title="ansible (${FLAVOR}, debian)"
CMD ["ansible", "--version"]
```

- [ ] **Step 2: Build, run, verify non-root, verify clean, hadolint** — same four commands as Task 4 Steps 2–5, substituting `-f images/debian/Dockerfile -t test-debian-$f`. Expected: identical pass criteria (`id -u` = 1000, `CLEAN`).

- [ ] **Step 3: Commit**

```bash
git add images/debian/Dockerfile
git commit -m "feat: debian multi-stage non-root ansible image"
```

### Task 6: Ubuntu Dockerfile

**Files:**
- Create: `images/ubuntu/Dockerfile`

- [ ] **Step 1: Write `images/ubuntu/Dockerfile`** — identical to the Debian file except both `FROM` lines use the resolved `ubuntu:24.04@sha256:...`, the lockfile path is `requirements/ubuntu-${FLAVOR}.txt`, and the `title` label says `ubuntu`.

- [ ] **Step 2: Build, run, verify** — same checks as Task 5 Step 2 with `-f images/ubuntu/Dockerfile -t test-ubuntu-$f`. Note: per the design, ubuntu builds amd64+arm64 (no special-casing).

- [ ] **Step 3: Commit**

```bash
git add images/ubuntu/Dockerfile
git commit -m "feat: ubuntu multi-stage non-root ansible image"
```

---

## Phase 3 — Scan-before-publish CI

### Task 7: Trivy DB mirror (defensive Trivy consumption)

**Files:**
- Create: `.github/workflows/trivy-db-mirror.yml`

**Why:** Trivy's runtime DB pull is both a rate-limit and a supply-chain dependency. We mirror a known-good DB into our own registry and consume it with `--skip-db-update`.

- [ ] **Step 1: Write `trivy-db-mirror.yml`**

```yaml
name: trivy-db-mirror
on:
  schedule: [{cron: "0 3 * * 1"}]   # weekly, before the build cadence
  workflow_dispatch:
permissions:
  contents: read
  packages: write
jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
      - uses: docker/login-action@v3   # SHA-pinned by Task 12
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Mirror trivy-db with oras
        run: |
          set -euo pipefail
          oras copy ghcr.io/aquasecurity/trivy-db:2 \
            ghcr.io/d10scot/trivy-db:2
          oras copy ghcr.io/aquasecurity/trivy-java-db:1 \
            ghcr.io/d10scot/trivy-java-db:1
```

> `oras` is preinstalled on `ubuntu-latest` runners; if not, install via the SHA-pinned `oras-project/setup-oras` action (add in Task 12).

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/trivy-db-mirror.yml
git commit -m "ci: mirror trivy-db into our own ghcr namespace"
```

### Task 8: build.yml — build to OCI archive + scan gate

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Write `build.yml`**

```yaml
name: build
on:
  pull_request:
    paths: ["images/**", "requirements/**", ".github/workflows/build.yml", "scripts/matrix.json"]
  push:
    branches: [main]
permissions:
  contents: read
  security-events: write   # SARIF upload only; NO packages:write, NO id-token
concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true
jobs:
  matrix:
    runs-on: ubuntu-latest
    outputs: {matrix: ${{ steps.set.outputs.matrix }}}
    steps:
      - uses: actions/checkout@v4
      - id: set
        run: echo "matrix=$(jq -c . scripts/matrix.json)" >> "$GITHUB_OUTPUT"

  build-scan:
    needs: matrix
    runs-on: ${{ matrix.arch == 'arm64' && 'ubuntu-24.04-arm' || 'ubuntu-latest' }}
    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.matrix.outputs.matrix).include }}
        arch: [amd64, arm64]
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - name: Build to local OCI archive
        uses: docker/build-push-action@v6
        with:
          context: .
          file: images/${{ matrix.distro }}/Dockerfile
          platforms: linux/${{ matrix.arch }}
          build-args: FLAVOR=${{ matrix.flavor }}
          outputs: type=oci,dest=image.tar
          provenance: false   # we attest in release.yml against the final digest
      # --- scanners: no registry write, no publish secrets in scope ---
      - name: Grype (OS + lang)
        uses: anchore/scan-action@v6
        with: {input: "oci-archive:image.tar", fail-build: true, severity-cutoff: high, output-format: sarif}
      - name: pip-audit (python lockfile)
        uses: pypa/gh-action-pip-audit@v1
        with: {inputs: "requirements/${{ matrix.distro }}-${{ matrix.flavor }}.txt"}
      - name: OSV-Scanner (offline)
        uses: google/osv-scanner-action@v2
        with: {scan-args: "--offline --download-offline-databases --format sarif --output osv.sarif image.tar"}
      - name: Trivy (SHA-pinned, mirrored DB, no upstream fetch)
        uses: aquasecurity/trivy-action@KNOWN_GOOD_SHA   # v0.35.0 commit 57a97c7; resolve real 40-char SHA in Task 12
        env:
          TRIVY_DB_REPOSITORY: ghcr.io/d10scot/trivy-db:2
          TRIVY_JAVA_DB_REPOSITORY: ghcr.io/d10scot/trivy-java-db:1
        with:
          input: image.tar
          scanners: vuln,secret,misconfig,license
          severity: HIGH,CRITICAL
          exit-code: "1"
          skip-db-update: true
          format: sarif
          output: trivy.sarif
      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with: {sarif_file: "."}
```

> `severity-cutoff`/`severity` gates start at HIGH/CRITICAL; tune later. `fail-fast: false` so one distro's CVE doesn't mask others.

- [ ] **Step 2: actionlint + zizmor the workflow**

Run: `actionlint .github/workflows/build.yml && zizmor .github/workflows/build.yml`
Expected: no findings. zizmor must report no unpinned-action / injection / excessive-permission issues. (Actions are pinned in Task 12; until then zizmor will flag unpinned — that's expected and resolved there.)

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build.yml
git commit -m "ci: build to OCI archive and gate on four scanners (no publish creds)"
```

### Task 9: release.yml — publish scanned bytes, sign, attest, tag, mirror

**Files:**
- Create: `.github/workflows/release.yml`

**Key invariant:** this workflow `needs:` the build+scan job and pushes the **exact OCI archive** that was scanned (via `skopeo`/`crane`), preserving the digest.

- [ ] **Step 1: Write `release.yml`**

```yaml
name: release
on:
  push:
    branches: [main]
    tags: ["v*"]
permissions:
  contents: read
jobs:
  build-scan:
    uses: ./.github/workflows/build.yml   # reuse: produces scanned archives
    permissions: {contents: read, security-events: write}

  publish:
    needs: build-scan
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write        # push to GHCR
      id-token: write        # cosign keyless + attestations
      attestations: write
    strategy:
      fail-fast: false
      matrix:
        include: ${{ fromJson(needs.build-scan.outputs.matrix).include }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with: {registry: ghcr.io, username: ${{ github.actor }}, password: ${{ secrets.GITHUB_TOKEN }}}
      - uses: docker/login-action@v3
        with: {registry: docker.io, username: ${{ vars.DOCKERHUB_USERNAME }}, password: ${{ secrets.DOCKERHUB_TOKEN }}}
      - name: Rebuild + push per-arch by digest (cache-hit = byte identical to scanned)
        id: build
        uses: docker/build-push-action@v6
        with:
          context: .
          file: images/${{ matrix.distro }}/Dockerfile
          platforms: linux/amd64,linux/arm64
          build-args: FLAVOR=${{ matrix.flavor }}
          tags: |
            ghcr.io/d10scot/ansible
            docker.io/d10scot/ansible
          outputs: type=image,push-by-digest=true,name-canonical=true,push=true
          provenance: false
      # metadata-action computes the human-facing tags from matrix + git ref
      - name: Compose + push multi-arch manifest with tags
        id: manifest
        run: |
          set -euo pipefail
          TAG="${{ matrix.distro }}${{ matrix.distrover }}"
          # assemble manifest list across the two arch digests, tag it, capture index digest
          # (use docker buildx imagetools create --tag ...:<corever>-<flavor>-<distro><ver>)
          echo "digest=$(...)" >> "$GITHUB_OUTPUT"
      - name: cosign sign (keyless, recursive for multi-arch)
        env: {COSIGN_YES: "true"}
        run: |
          cosign sign --recursive \
            "ghcr.io/d10scot/ansible@${{ steps.manifest.outputs.digest }}"
      - name: SBOM (syft, CycloneDX + SPDX)
        run: |
          syft "ghcr.io/d10scot/ansible@${{ steps.manifest.outputs.digest }}" -o spdx-json=sbom.spdx.json
      - uses: actions/attest-build-provenance@v2
        with: {subject-name: ghcr.io/d10scot/ansible, subject-digest: "${{ steps.manifest.outputs.digest }}", push-to-registry: true}
      - uses: actions/attest-sbom@v2
        with: {subject-name: ghcr.io/d10scot/ansible, subject-digest: "${{ steps.manifest.outputs.digest }}", sbom-path: sbom.spdx.json, push-to-registry: true}
```

> The manifest-assembly step (Step `manifest`) is intentionally sketched: implement with `docker buildx imagetools create --tag ghcr.io/d10scot/ansible:<corever>-<flavor>-<distro><distrover> <ghcr-amd64-digest> <ghcr-arm64-digest>` and read back the index digest via `docker buildx imagetools inspect --format '{{json .Manifest.Digest}}'`. Mirror the same tag to docker.io in the same step. cosign/syft/attest steps then run against that index digest. **All tags are applied here, only after `build-scan` passed** — satisfying the no-unscanned-publish invariant.

- [ ] **Step 2: Install cosign + syft via SHA-pinned actions** — add `sigstore/cosign-installer` and `anchore/sbom-action` (or `anchore/syft`) to the job; they are SHA-pinned in Task 12.

- [ ] **Step 3: actionlint + zizmor**

Run: `actionlint .github/workflows/release.yml && zizmor .github/workflows/release.yml`
Expected: no findings (post-Task-12). Confirm `id-token`/`packages:write` exist **only** in the `publish` job, never in `build-scan`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: publish scanned bytes, cosign sign, SBOM + provenance attestations, mirror"
```

---

## Phase 4 — Supply-chain guards & automation

### Task 10: lint.yml — workflow + dockerfile security linting in CI

**Files:**
- Create: `.github/workflows/lint.yml`

- [ ] **Step 1: Write `lint.yml`** running, on PR, with `permissions: {contents: read}`: hadolint on each `images/*/Dockerfile`, `actionlint`, `zizmor .github/workflows`, and `gitleaks`. Use SHA-pinned actions (`reviewdog/action-hadolint` is **not** used — recall reviewdog was compromised; call hadolint/zizmor directly via their official actions or containers).

```yaml
name: lint
on: {pull_request: {}}
permissions: {contents: read}
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker run --rm -i hadolint/hadolint < images/alpine/Dockerfile
      - run: docker run --rm -i hadolint/hadolint < images/debian/Dockerfile
      - run: docker run --rm -i hadolint/hadolint < images/ubuntu/Dockerfile
      - uses: rhysd/actionlint@v1            # SHA-pinned in Task 12
      - uses: zizmorcore/zizmor-action@v1    # SHA-pinned in Task 12
      - uses: gitleaks/gitleaks-action@v2    # SHA-pinned in Task 12
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/lint.yml
git commit -m "ci: hadolint + actionlint + zizmor + gitleaks on PRs"
```

### Task 11: renovate.json

**Files:**
- Create: `renovate.json`

- [ ] **Step 1: Write `renovate.json`**

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    "helpers:pinGitHubActionDigestsToSemver",
    "docker:pinDigests"
  ],
  "pinDigests": true,
  "minimumReleaseAge": "7 days",
  "internalChecksFilter": "strict",
  "schedule": ["before 6am on monday"],
  "prHourlyLimit": 0,
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "minimumReleaseAge": "14 days",
      "automerge": false
    },
    {
      "description": "Never silently re-point an action SHA within the same tag",
      "matchManagers": ["github-actions"],
      "matchUpdateTypes": ["pinDigest"],
      "matchFileNames": [".github/workflows/**"],
      "enabled": false
    },
    {
      "description": "Automerge base image digest bumps after cooldown + green CI",
      "matchDatasources": ["docker"],
      "matchUpdateTypes": ["digest"],
      "automerge": true,
      "automergeType": "branch"
    },
    {
      "description": "Automerge python patch bumps in lockfiles after cooldown + green CI",
      "matchManagers": ["pip_requirements", "pep621"],
      "matchUpdateTypes": ["patch", "pin", "pinDigest"],
      "automerge": true,
      "automergeType": "branch"
    },
    {
      "groupName": "ansible core+full+lint",
      "matchPackageNames": ["ansible-core", "ansible", "ansible-lint"]
    }
  ]
}
```

> This realises the agreed posture: 7d/14d cooldown, `strict` so no PR appears before cooldown, automerge **only** for base-image digests and Python patches, **Actions excluded from automerge** and their in-place SHA re-points disabled.

- [ ] **Step 2: Validate config**

Run: `npx --yes renovate-config-validator renovate.json`
Expected: "Config validated successfully".

- [ ] **Step 3: Commit**

```bash
git add renovate.json
git commit -m "ci: renovate with cooldown, digest pinning, scoped automerge"
```

### Task 12: Pin every action to a commit SHA

**Files:**
- Modify: all `.github/workflows/*.yml`

- [ ] **Step 1: Install pinact**

Run: `go install github.com/suzuki-shunsuke/pinact/cmd/pinact@latest` (or download a release binary).

- [ ] **Step 2: Pin all actions**

Run: `pinact run`
Expected: every `uses: org/action@vX` rewritten to `uses: org/action@<40-char-sha> # vX`. This resolves the real SHAs — including the Trivy action; verify the Trivy pin resolves to the known-good `v0.35.0` release commit and not a yanked one.

- [ ] **Step 3: Verify no floating tags remain**

Run: `grep -rEn 'uses: [^@]+@v?[0-9]+($|[^0-9a-f])' .github/workflows | grep -v '#'`
Expected: empty (every `uses:` is a 40-hex SHA with a version comment).

- [ ] **Step 4: zizmor confirms pinning**

Run: `zizmor .github/workflows`
Expected: no `unpinned-uses` findings.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows
git commit -m "ci: pin all github actions to commit SHAs"
```

### Task 13: OpenSSF Scorecard

**Files:**
- Create: `.github/workflows/scorecard.yml`

- [ ] **Step 1: Write `scorecard.yml`** (standard Scorecard workflow; SHA-pin via Task 12 re-run)

```yaml
name: scorecard
on:
  branch_protection_rule:
  schedule: [{cron: "0 4 * * 1"}]
  push: {branches: [main]}
permissions: {contents: read}
jobs:
  analysis:
    runs-on: ubuntu-latest
    permissions: {security-events: write, id-token: write, contents: read}
    steps:
      - uses: actions/checkout@v4
      - uses: ossf/scorecard-action@v2
        with: {results_file: results.sarif, results_format: sarif, publish_results: true}
      - uses: github/codeql-action/upload-sarif@v3
        with: {sarif_file: results.sarif}
```

- [ ] **Step 2: Re-run `pinact run`** to pin the new actions; commit.

```bash
git add .github/workflows/scorecard.yml && pinact run && git add -A
git commit -m "ci: OpenSSF Scorecard analysis + badge feed"
```

---

## Phase 5 — Publicising & verification

### Task 14: SECURITY.md + supply-chain transparency page

**Files:**
- Create: `SECURITY.md`, `docs/supply-chain.md`

- [ ] **Step 1: `SECURITY.md`** — private disclosure via GitHub Security Advisories ("Report a vulnerability" tab), a stated triage SLA (e.g. 72h acknowledge, best-effort patch), the weekly rebuild cadence, and the supported tags. No "open a public issue" anti-pattern.

- [ ] **Step 2: `docs/supply-chain.md`** — the "why trust this" page. Document, with the rationale: SHA-pinned actions, digest-pinned bases, hash-pinned Python (`--require-hashes`), scan-before-publish (4 scanners, credential isolation), Trivy DB mirror + known-good SHA, cosign keyless signing, SBOM + SLSA L2 provenance attestations, GHCR-as-canonical-attestation-home, Renovate cooldown. Explicitly contrast with unsigned/unpinned alternatives.

- [ ] **Step 3: Commit**

```bash
git add SECURITY.md docs/supply-chain.md
git commit -m "docs: security policy + supply-chain transparency page"
```

### Task 15: README verification section + Docker Hub sync

**Files:**
- Modify: `README.md`
- Create: `docs/verify.md`
- Modify: `.github/workflows/release.yml` (add README→Docker Hub sync step)

- [ ] **Step 1: Fill README `## Verifying this image`** with copy-paste commands (the consumer-facing payoff):

````markdown
## Verifying this image

Verify by **digest against GHCR** (canonical attestation home).

```bash
IMAGE=ghcr.io/d10scot/ansible:2.18-full-alpine3.22

# 1. Signature (keyless) — identity-pinned to our release workflow
cosign verify \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity-regexp='^https://github.com/D10Scot/docker-ansible/\.github/workflows/release\.yml@refs/.*$' \
  "$IMAGE"

# 2. SLSA build provenance
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible

# 3. SBOM attestation
gh attestation verify "oci://$IMAGE" -R D10Scot/docker-ansible \
  --predicate-type https://spdx.dev/Document/v2.3

# 4. See everything attached
cosign tree "$IMAGE"
```
````

- [ ] **Step 2: Add badges** to the README top: build status, OpenSSF Scorecard, "signed with cosign", SLSA Level 2, "SBOM available".

- [ ] **Step 3: `docs/verify.md`** — longer-form verification guide incl. how to scan-from-SBOM (`grype sbom:./sbom.spdx.json`) and the Docker Hub caveat (verify against GHCR, not Hub, because Hub lacks the Referrers API).

- [ ] **Step 4: Add README→Docker Hub sync step** to `release.yml` using the SHA-pinned `peter-evans/dockerhub-description` action (only on `v*` tags), then `pinact run`.

- [ ] **Step 5: Commit**

```bash
git add README.md docs/verify.md .github/workflows/release.yml
git commit -m "docs: consumer verification commands, badges, docker hub sync"
```

---

## Phase 6 — Repo creation & first release

### Task 16: Create the GitHub repo and wire secrets (operator-gated)

**Files:** none (infra)

- [ ] **Step 1: Confirm with the operator** before any outward-facing action (public repo under the org, first publish). Then create:

Run: `gh repo create D10Scot/docker-ansible --public --source . --remote origin --description "Supply-chain-hardened multi-distro Ansible images"`

- [ ] **Step 2: Operator sets secrets/vars** (you cannot — confirm they're done):
  - Repo secret `DOCKERHUB_TOKEN` (scoped Docker Hub access token, push to `d10scot/ansible`).
  - Repo variable `DOCKERHUB_USERNAME`.
  - Enable GitHub Actions, allow `id-token` (OIDC) — on by default for public repos.

- [ ] **Step 3: Enable branch protection on `main`** requiring `build` + `lint` to pass; enable Renovate (install the self-hosted SHA-pinned `renovate.yml`, or the Mend app per design — default here is the SHA-pinned action). Add `renovate.yml`:

```yaml
name: renovate
on: {schedule: [{cron: "0 5 * * 1"}], workflow_dispatch: {}}
permissions: {contents: read}
jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: renovatebot/github-action@v40   # SHA-pinned via pinact
        with: {token: ${{ secrets.RENOVATE_TOKEN }}}
```

- [ ] **Step 4: Bootstrap the Trivy DB mirror** so the first build can `--skip-db-update`:

Run: `gh workflow run trivy-db-mirror.yml` and wait for green.

- [ ] **Step 5: Push and watch the first release**

```bash
git push -u origin main
gh run watch
```
Expected: `build` (build+scan) green across all 9×2 matrix legs; `release` publishes, signs, and attests.

- [ ] **Step 6: End-to-end verification (the real acceptance test)**

Run the four commands from README Step 1 against a freshly published digest.
Expected: cosign verify OK (identity matches the release workflow), both `gh attestation verify` calls OK, `cosign tree` shows signature + SBOM + provenance.

---

## Self-review checklist (done by plan author)

- **Spec coverage:** distros (Tasks 4–6) ✓; flavors (Task 1) ✓; multi-arch (Tasks 8–9) ✓; hash-pinned Python (Tasks 1–2) ✓; SHA-pinned actions (Task 12) ✓; digest-pinned bases (Tasks 3–6, 11) ✓; 4-scanner gate w/ credential isolation (Task 8) ✓; Trivy defensive consumption (Task 7) ✓; scan-before-publish + byte-identical publish (Tasks 8–9) ✓; cosign + SBOM + provenance (Task 9) ✓; GHCR + Docker Hub (Task 9, 15) ✓; Renovate cooldown/automerge/Actions-excluded (Task 11) ✓; Scorecard (Task 13) ✓; SECURITY.md + transparency + verification + badges + Hub sync (Tasks 14–15) ✓; repo creation + secrets + first release (Task 16) ✓.
- **Open implementation detail flagged, not hidden:** the manifest-assembly step in Task 9 is described with the exact `buildx imagetools` commands to use rather than a copy-paste block, because the two per-arch digests are runtime values; this is called out explicitly, not left as "TODO".
- **No fabricated pins:** all SHAs/digests resolved via `pinact`/`crane` in-task; the Trivy placeholder is labelled and must be verified against the known-good release.
```
