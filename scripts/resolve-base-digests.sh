#!/usr/bin/env bash
set -euo pipefail
# Resolve current multi-arch index digests for the base images. Run crane via container.
for ref in alpine:3.22 debian:12 ubuntu:24.04; do
  digest=$(docker run --rm gcr.io/go-containerregistry/crane:latest digest "$ref")
  printf 'FROM %s@%s\n' "$ref" "$digest"
done
