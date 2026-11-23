#!/usr/bin/env bash
set -euo pipefail
# Resolve current multi-arch index digests for the base images using buildx
# (no third-party / unpinned helper image). Keep the tag list in sync with
# images/*/Dockerfile and .github/workflows/lock.yml.
for ref in alpine:3.22 debian:13 ubuntu:24.04; do
  digest=$(docker buildx imagetools inspect "$ref" --format '{{json .Manifest}}' | jq -r .digest)
  printf 'FROM %s@%s\n' "$ref" "$digest"
done
