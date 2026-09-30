#!/bin/sh
# Usage: write-attestations.sh <output.json>
# Writes the coverage, SBOM and scan attestations for the report action.
# Coverage is read from the Cobertura fixture's line-rate, because the action
# takes coverage as a number rather than a file.
set -eu

out="$1"
rate=$(sed -n 's/.*<coverage line-rate="\([0-9.]*\)".*/\1/p' fixtures/coverage/cobertura.xml | head -n 1)
[ -n "$rate" ] || { echo "No line-rate in fixtures/coverage/cobertura.xml" >&2; exit 1; }
lines=$(awk -v r="$rate" 'BEGIN { printf "%.1f", r * 100 }')

cat > "$out" <<JSON
[
  { "kind": "coverage", "name": "canary-coverage", "data": { "lines": ${lines}, "threshold": 80 } },
  { "kind": "sbom", "name": "canary-sbom", "file": "fixtures/sbom.cdx.json", "data": { "format": "cyclonedx", "components": 3 } },
  { "kind": "scan", "name": "canary-sarif", "file": "fixtures/scan.sarif", "format": "sarif", "data": { "tool": "canary-fixture-scanner", "failOn": "high" } }
]
JSON

cat "$out"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "Canary fixtures: line coverage ${lines}%" >> "$GITHUB_STEP_SUMMARY"
fi
