# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please use GitHub's private disclosure mechanism instead:

1. Go to <https://github.com/D10Scot/docker-ansible/security/advisories>
2. Click **"Report a vulnerability"**
3. Fill in the details (affected tags, reproduction steps, potential impact)

We will acknowledge your report within **72 hours** and provide a best-effort fix as quickly as the severity warrants.

## Supported Tags

The following tags receive ongoing security maintenance via weekly automated rebuilds that refresh OS packages (`apk upgrade` / `apt upgrade`):

| Tag pattern | Description |
|---|---|
| `latest` | Alias for `full-alpine` |
| `<flavor>-<distro>` | Rolling — e.g. `full-alpine`, `core-debian`, `lint-ubuntu` |
| `<corever>-<flavor>-<distro>` | Immutable — e.g. `2.21.1-full-alpine` |

All tags are signed with cosign keyless signing and carry SBOM and SLSA build-provenance attestations. See [`docs/verify.md`](docs/verify.md) for verification commands.

Older immutable `<corever>-*` tags are **not** rebuilt and may accumulate OS-level CVEs over time. Pin to a rolling tag if you need automatic patch coverage, or accept responsibility for your own base-image updates when pinning to an immutable tag.

## Weekly Rebuild Cadence

A scheduled CI job rebuilds and republishes all rolling tags every week. This ensures that OS-level security patches released upstream (Alpine, Debian trixie, Ubuntu) are incorporated promptly even when there are no Ansible version changes.
