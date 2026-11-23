#!/usr/bin/env bash
# Fail closed on the vulnerability-ignore files: an entry that is expired, has no
# expiry or has no reason fails, and so does any key the scanner could honour but
# this check would not understand.
#
# Policy (AGENTS.md, "Supply chain"): exceptions to the fixable HIGH/CRITICAL gate
# live in a reviewed ignore file. Each has a reason and an expiry date, and CI
# fails on expired entries. Trivy honours `expired_at` itself. Grype has no expiry
# field and silently drops unknown keys, so this script is the only thing that
# enforces `expires` for Grype.
#
# The files are parsed with a real YAML parser: yq (Go yaml.v3, the YAML family
# Trivy and Grype also use), run as a digest-pinned container with no network.
# The result is converted to JSON and checked with jq. That way quoted keys,
# flow style, anchors and aliases are seen exactly as the scanners see them.
#
#   .trivyignore.yaml  top-level keys allowed: vulnerabilities misconfigurations secrets licenses
#                      each a list of mappings with keys from: id paths purls statement expired_at
#                      required per entry: id, statement, expired_at
#   .grype.yaml        top-level keys allowed: ignore   (any other Grype setting, e.g.
#                      exclude, ignore-states, only-fixed, fail-on-severity, could
#                      weaken the gate outside review, so it is rejected)
#                      each a mapping with keys from: vulnerability reason expires
#                        package fix-state namespace include-aliases vex-status
#                        vex-justification match-type
#                      required per entry: vulnerability, reason, expires
#
# Also rejected: an empty or comment-only file, multiple YAML documents, and
# duplicate mapping keys. Dates must be plain `YYYY-MM-DD`; an entry is expired on
# or after its date (UTC).
#
# Needs: bash, docker, jq.   Usage: scripts/check-ignore-expiry.sh [repo-root]
set -euo pipefail

# yq v4.54.2, published by mikefarah/yq's own docker-release workflow; index digest
# resolved with `docker buildx imagetools inspect ghcr.io/mikefarah/yq:4.54.2`.
YQ_IMAGE="ghcr.io/mikefarah/yq:4.54.2@sha256:5d56494617dce8311106e905aac5c080a2087c905a7f7de2984db2e2cc60ab2e"

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
today="$(date -u +%Y-%m-%d)"
status=0

command -v jq >/dev/null || { echo "FAIL: jq is required" >&2; exit 2; }
command -v docker >/dev/null || { echo "FAIL: docker is required (runs the pinned yq)" >&2; exit 2; }

# check FILE ALLOWED_TOP ENTRY_KEYS ID_KEY REASON_KEY EXPIRY_KEY  (lists as JSON arrays)
check() {
  local file="$1" allowed="$2" entrykeys="$3" idkey="$4" reasonkey="$5" expkey="$6"
  local json docs dups
  if [ ! -f "$file" ]; then
    echo "FAIL ${file}: file is missing"
    return 1
  fi
  if ! json=$(docker run --rm -i --network none "$YQ_IMAGE" -p yaml -o json -I 0 'explode(.)' <"$file"); then
    echo "FAIL ${file}: not valid YAML"
    return 1
  fi
  docs=$(printf '%s\n' "$json" | grep -c .)
  if [ "$docs" -ne 1 ]; then
    echo "FAIL ${file}: must be exactly one YAML document, found ${docs}"
    return 1
  fi
  # yq keeps both copies of a duplicated key but jq keeps only the last, and the
  # scanners' parsers may pick either. Ask yq, on the YAML itself, for any mapping
  # whose keys repeat.
  if ! dups=$(docker run --rm -i --network none "$YQ_IMAGE" -p yaml -o json -I 0 \
      '[.. | select(tag == "!!map") | keys | select(length != (unique | length))
        | group_by(.) | map(select(length > 1) | .[0])] | flatten' <"$file"); then
    echo "FAIL ${file}: duplicate-key check failed"
    return 1
  fi
  if [ "$dups" != "[]" ]; then
    echo "FAIL ${file}: duplicate mapping key(s): ${dups}"
    return 1
  fi
  printf '%s\n' "$json" | jq -r --arg file "$file" --arg today "$today" \
    --argjson allowed "$allowed" --argjson entrykeys "$entrykeys" \
    --arg idkey "$idkey" --arg reasonkey "$reasonkey" --arg expkey "$expkey" '
    def isdate: type == "string"
      and test("^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$");
    def nonempty: type == "string" and (gsub("\\s"; "") | length) > 0;
    def allowedin($list): . as $k | $list | any(. == $k);
    if type != "object" then
      "FAIL \($file): top level must be a mapping (got \(type)); an empty file is not allowed"
    else
      ( keys[] | select(allowedin($allowed) | not)
        | "FAIL \($file): top-level key \"\(.)\" is not allowed (allowed: \($allowed | join(", ")))" ),
      ( to_entries[] | select(.key | allowedin($allowed)) | .key as $sec | .value as $list
        | if ($list | type) != "array" then
            "FAIL \($file): \"\($sec)\" must be a list (got \($list | type))"
          else
            $list | to_entries[] | .key as $i | .value as $e
            | (if ($e | type) == "object" and ($e[$idkey] | nonempty)
               then "\($sec)[\($i)] \($e[$idkey])" else "\($sec)[\($i)]" end) as $at
            | if ($e | type) != "object" then
                "FAIL \($file): \($at): entry must be a mapping (got \($e | type))"
              else
                [ ( $e | keys[] | select(allowedin($entrykeys) | not)
                    | "FAIL \($file): \($at): key \"\(.)\" is not allowed" ),
                  ( if ($e[$idkey] | nonempty) then empty
                    else "FAIL \($file): \($at): has no \($idkey)" end ),
                  ( if ($e[$reasonkey] | nonempty) then empty
                    else "FAIL \($file): \($at): has no \($reasonkey)" end ),
                  ( if $e[$expkey] == null then "FAIL \($file): \($at): has no \($expkey)"
                    elif ($e[$expkey] | isdate | not) then
                      "FAIL \($file): \($at): \($expkey) \($e[$expkey] | tojson) is not YYYY-MM-DD"
                    elif $e[$expkey] <= $today then
                      "FAIL \($file): \($at): expired on \($e[$expkey]) (today \($today))"
                    else empty end )
                ] as $errs
                | if ($errs | length) > 0 then $errs[]
                  else "ok   \($file): \($at): expires \($e[$expkey])" end
              end
          end ),
      "\($file): \([.[] | arrays | length] | add // 0) entries checked"
    end
  ' | { fail=0; while IFS= read -r line; do
          printf '%s\n' "$line"
          case "$line" in FAIL*) fail=1 ;; esac
        done; exit "$fail"; }
}

check "${root}/.trivyignore.yaml" \
  '["vulnerabilities","misconfigurations","secrets","licenses"]' \
  '["id","paths","purls","statement","expired_at"]' \
  id statement expired_at || status=1
check "${root}/.grype.yaml" \
  '["ignore"]' \
  '["vulnerability","reason","expires","package","fix-state","namespace","include-aliases","vex-status","vex-justification","match-type"]' \
  vulnerability reason expires || status=1

if [ "$status" -ne 0 ]; then
  echo "Ignore-file policy violated: see FAIL lines above." >&2
fi
exit "$status"
