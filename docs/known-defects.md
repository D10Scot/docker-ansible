# Known defects and accepted deviations

This register lists defects that exist today, and deviations we have accepted on
purpose. Read it before you "fix" code near one of them, so that you know what is
already there and do not bring back something removed on purpose. Each entry says how
it was checked and whether it is **open** (should be fixed) or **accepted** (kept on
purpose, with the reason).

Last reviewed: 2026-11-23.

## Pipeline and scheduling

| # | Status | Defect | Evidence / reason |
|---|---|---|---|
| D1 | Open (operator) | **Renovate is configured but not installed.** `renovate.json` exists, but no Renovate app or workflow runs, so no dependency PRs are opened. | No Renovate workflow in `.github/workflows/`; the owner is installing it. |
| D2 | Open | **Scheduled workflows auto-disable after 60 days without repository activity** (GitHub behaviour for public repos). If that happens, the weekly rebuild in `build.yml` and the Trivy DB mirror stop silently, and the rolling tags stop getting OS patches. | Documented GitHub behaviour. The keepalive is the Renovate commits once D1 is done. Until then, re-enable the workflows in the Actions tab if they are disabled. |
| D3 | Accepted | **One failing variant blocks the weekly publish of all nine.** `publish` needs the whole `build-scan` matrix, so a single blocking finding in one distro/flavor/arch holds back every variant's OS patches. | `build.yml`, `publish.needs: [ignore-expiry, build-scan]`. Accepted: pip-audit and OSV-Scanner run only in `build-scan`, and gating publish on them per variant would need a matrix-aware `needs`. |
| D4 | Accepted | **Failed verifies leave orphan untagged digests on GHCR.** `stage` pushes by digest before `verify`. If verify fails, that digest stays in the package, untagged and unsigned, and can be pulled by digest. | `publish.yml`, the `stage` job. Accepted: no tag or signature ever points at it, and a "delete untagged" GC on GHCR would also delete cosign signatures and attestations, which are stored as untagged manifests (see the design spec, "Risks"). |
| D5 | Accepted | **The Trivy DB can be up to a week old.** Trivy reads the weekly mirror (`trivy-db-mirror.yml`, Mon 03:00 UTC) through `TRIVY_DB_REPOSITORY`; it does not use `--skip-db-update`. Grype pulls its DB live from Anchore and is not mirrored. | `trivy-db-mirror.yml`; the Trivy steps' `env`. Accepted in exchange for not trusting the upstream Trivy DB at scan time. Grype, as an independent DB, catches what a stale Trivy DB misses. |
| D6 | Accepted | **The dated-tag check is check-then-create.** `promote` checks that `<core>-<flavor>-<distro>-<YYYYMMDD>` is absent and then creates it. A writer outside this workflow could race it. | `publish.yml`, the promote step. Runs on `main` are serialised by the `build-${ref}` concurrency group, and each variant writes distinct tags. A same-day rerun keeps the first build's dated tag and logs a notice. |
| D7 | Accepted | **The digest assertion runs after the tags move.** `promote` asserts that every tag resolves to the verified digest *after* `imagetools create`. It detects a mismatch and fails the run, but cannot undo the tag move. | `publish.yml`. Break-checked locally: tagging a different digest fails with `… resolves to sha256:…, expected verified digest sha256:…`. A registry cannot create a tag conditionally. |
| D8 | Open | **The `$/` self-repository syntax is not adopted.** zizmor's `self-repository` audit is suppressed inline on the `uses: ./.github/workflows/publish.yml` call. | `build.yml`, the `publish` job. How `$/` (which resolves to the running commit) changes the OIDC `job_workflow_ref`, and so the documented signer identity `…/publish.yml@refs/heads/main`, has not been verified. Switch only after a test run shows the claim. |

## Images

| # | Status | Defect | Evidence / reason |
|---|---|---|---|
| I1 | Accepted | **The runtime images keep the OS package manager** (`apk` on Alpine, `apt-get` on Debian/Ubuntu) **and `pip`** in `/opt/ansible`. This is against the "no package manager in the runtime stage" hardening rule. | `docker run … core-alpine`: `/sbin/apk`, `pip 26.1.2`; `core-debian`: `/usr/bin/apt-get`, `pip 26.1.2`. Accepted because downstream users extend the image (extra collections, system packages). `pip` itself is being hash-pinned in a separate PR. |
| I2 | Accepted | **The Debian runtime ships perl**, pulled in as a dependency of `git`. | `docker run … core-debian`: `/usr/bin/perl` (perl v5.40.1). `git` is needed by `ansible-galaxy` and for git-sourced roles. |
| I3 | Open | **The SBOM attached to the multi-arch index describes only amd64.** syft resolves the index to the runner's platform, so arm64 packages are not listed. | `gh attestation verify oci://ghcr.io/d10scot/ansible:latest … --predicate-type https://spdx.dev/Document/v2.3`: package URLs carry `arch=x86_64` only. Fix: one SBOM per platform manifest, attested against the child digests. |

## Distribution and verification

| # | Status | Defect | Evidence / reason |
|---|---|---|---|
| V1 | Accepted | **Docker Hub carries no attestations or signatures.** Docker Hub has no OCI Referrers API, and we sign only on GHCR. | `docs/verify.md`. The digest is identical on both registries, so verify against `ghcr.io/d10scot/ansible@<digest>`. |
| V2 | Open | **With cosign v3, `cosign verify` is also satisfied by the attestation bundles.** By default it returned the provenance and SBOM bundles (each signed by the same workflow identity) rather than the legacy `.sig` signature; with `--new-bundle-format=false` it returned the `.sig`. Either way the signer is our workflow, but the check is not specifically the cosign signature. | Observed with cosign v3.1.4 against `ghcr.io/d10scot/ansible:latest` on 2026-11-23. Consider signing in the new bundle format, or documenting `--new-bundle-format=false`. |
| V3 | Accepted | **Digests published before `publish.yml` are SLSA Build L2, signed by `build.yml`.** | `docs/verify.md`, "Images published before the reusable workflow". Old digests are not re-signed. |
