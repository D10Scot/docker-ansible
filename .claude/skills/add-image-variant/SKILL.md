---
name: add-image-variant
description: Use when adding a new image FLAVOR (e.g. a "minimal" flavor) or a new base DISTRO to this docker-ansible project. Covers the requirements, hash-pinned lockfiles, CI matrix, Dockerfiles, AND keeping docs/dockerhub-overview.md + README in sync so the Docker Hub overview never drifts. Triggers on phrasings like "add a flavour/flavor", "add a distro", "new image variant", "support Fedora", "add a lint-minimal image".
---

# Adding an image variant (flavor or distro)

This project publishes `flavor × distro × arch` images. Adding a variant touches several
files **in lockstep** — including the **Docker Hub overview**, which is hand-maintained
copy that will silently go stale if you skip it. That overview step is the reason this
skill exists: do not finish without it.

Create a TodoWrite item per step below and complete them in order.

## Source-of-truth files (what defines a variant)

- **Flavors** = `requirements/<flavor>.in` + the `flavor:` axis in
  `.github/workflows/build.yml` (it appears in TWO matrices — the `build-scan` job and
  the `publish` job; update both).
- **Distros** = `images/<distro>/Dockerfile` + the `distro:` axis in `build.yml` (again
  both matrices) + the matrix in `.github/workflows/lock.yml`.
- **Lockfiles** = `requirements/<distro>-<flavor>-<arch>.txt` (one per combination,
  fully hash-pinned; `arch` ∈ {amd64, arm64}).
- **Docker Hub overview** = `docs/dockerhub-overview.md` — the **Flavors** list under
  "Choose your image" and the **Distros & arches** table. Synced to Docker Hub by the
  `dockerhub-overview` workflow whenever this file changes (no image rebuild needed).
- The Dockerfiles are flavor-agnostic: they install
  `requirements/<distro>-${FLAVOR}-${TARGETARCH}.txt` by name, so a new flavor needs **no
  Dockerfile change** — only the lockfiles must exist.

## Adding a new FLAVOR (e.g. `minimal`)

1. **Declare deps** — create `requirements/<flavor>.in` following the existing pattern:
   pin `ansible-core==<ver>`, reuse shared constraints via `-c core.in` (or `-c full.in`),
   and keep `setuptools` pinned (Debian's venv ships a CVE-affected setuptools).
   Also list `pip` (unpinned): the Dockerfiles no longer run `pip install --upgrade pip`
   (unhashed); the hash-pinned `pip` in each lockfile is installed by the
   `--require-hashes` install.
2. **Generate lockfiles** — produce `requirements/<distro>-<flavor>-<arch>.txt` for all
   3 distros × 2 arches (6 files). Preferred: `gh workflow run lock.yml`, wait, download
   the artifacts, and commit them. Or generate locally with `scripts/lock.sh <distro>`
   run **inside the digest-pinned base image** with a pinned `uv` mounted on PATH (see
   `lock.yml` for the exact `docker run`), so the distro's Python version is used; do NOT use `--universal` — it pulls
   ansible-lint's yanked win32 sentinel). Verify all are hashed:
   `grep -L -- '--hash=sha256' requirements/*-<flavor>-*.txt` must print nothing.
3. **Add to the CI matrix** — add `<flavor>` to the `flavor: [...]` list in BOTH the
   `build-scan` and `publish` jobs in `.github/workflows/build.yml`.
4. **⭑ Update the Docker Hub overview (REQUIRED)** — in `docs/dockerhub-overview.md`, add
   a bullet to the **Flavors** list under "Choose your image" describing what the flavor
   includes (match the existing tone). The `dockerhub-overview` workflow auto-syncs it on
   push.
5. **Update the README** — add the flavor to any flavor/tag description in `README.md`.
6. **Verify locally before pushing**:
   ```bash
   docker build --build-arg FLAVOR=<flavor> -f images/alpine/Dockerfile -t variant-check .
   docker run --rm variant-check ansible --version   # and id -u must be 1000
   ```

## Relocking (Renovate bumped a `requirements/*.in` pin, or you edited one)

Renovate bumps only the direct `name==version` pins in `requirements/*.in`. The lockfiles
are not touched, so `scripts/check-lock-consistency.sh` (a step in `lint.yml`) fails the PR
until they are regenerated. That red check is the intended signal, not a bug:

```bash
gh workflow run lock.yml --repo D10Scot/docker-ansible --ref <branch>
gh run watch --repo D10Scot/docker-ansible          # pick the lock run
gh run download <run-id> --repo D10Scot/docker-ansible --dir /tmp/locks
cp /tmp/locks/lock-*/*.txt requirements/            # 18 files
sh scripts/check-lock-consistency.sh                 # must print "lock consistency OK"
```

Then commit the lockfiles to the same branch. Local alternative (same recipe as CI): extract
`/uv` from the `UV_IMAGE` in `lock.yml` with `docker create` + `docker cp`, then for each
distro `docker run --rm -v "$PWD:/w" -v "<uv>:/usr/local/bin/uv:ro" -w /w <base@digest> sh /w/scripts/lock.sh <distro>`
(base image + digest from the `lock.yml` matrix).

## Adding a new DISTRO (e.g. `fedora`)

1. **Dockerfile** — create `images/<distro>/Dockerfile` modelled on an existing one:
   multi-stage; **digest-pinned** base + OS security upgrade in the runtime stage;
   non-root `ansible` user (uid 1000); install with
   `pip install --require-hashes -r requirements/<distro>-${FLAVOR}-${TARGETARCH}.txt`;
   no HEALTHCHECK. Resolve the base digest via `scripts/resolve-base-digests.sh`.
2. **lock.yml matrix** — add `- {distro: <distro>, image: "<base>:<tag>"}` to
   `.github/workflows/lock.yml` (digest-pinned, same digest as the Dockerfile `FROM`;
   Renovate groups the two as "base images"). Also add the distro's Docker Hub image name
   (e.g. `fedora`) to the `matchPackageNames` of BOTH `renovate.json` rules that list
   `alpine`, `debian`, `ubuntu`: the "base images" group and the digest automerge rule.
   Otherwise its bumps are neither grouped with the lock.yml matrix nor automerged.
   `scripts/check-lock-consistency.sh` derives the expected lockfiles from `images/*/`,
   so a new distro dir without its 6 lockfiles fails lint.
3. **Lockfiles** — generate `requirements/<distro>-<flavor>-<arch>.txt` for every flavor
   × arch (run the lock workflow). Verify all are hashed.
4. **CI matrix** — add `<distro>` to the `distro: [...]` list in BOTH the `build-scan` and
   `publish` jobs in `build.yml`.
5. **⭑ Update the Docker Hub overview (REQUIRED)** — in `docs/dockerhub-overview.md`, add
   a row to the **Distros & arches** table (distro · version · arches).
6. **Update the README** — distro table / tag examples if present.
7. **Verify locally** — build one flavor on the new distro and run `ansible --version`.

## Why the overview step is mandatory

The overview deliberately documents the **tag scheme** and points to Docker Hub's **Tags
tab** for the live tag list — so brand-new *tags* (e.g. a new `ansible-core` version)
appear automatically with no doc change. But a new *flavor* or *distro* changes the
hand-written **Flavors list** / **Distros table**, which Docker Hub cannot regenerate on
its own. Skipping `docs/dockerhub-overview.md` leaves the overview lying about what the
repo ships. Updating it is a one-line edit that publishes itself.

## Done check

- [ ] New `.in` (flavor) or `Dockerfile` (distro) committed
- [ ] All new lockfiles present and fully hash-pinned
- [ ] `flavor:`/`distro:` added to BOTH matrices in `build.yml` (+ `lock.yml` for a distro)
- [ ] `docs/dockerhub-overview.md` updated (Flavors list or Distros table)
- [ ] `README.md` updated if it enumerates flavors/distros
- [ ] Built and ran one leg locally (`ansible --version`, `id -u` = 1000)
