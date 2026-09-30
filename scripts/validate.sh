#!/bin/sh
# Checks the static fixtures before they are reported. POSIX sh only, so it
# runs on ubuntu runners and on alpine images alike.
set -eu

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }

for f in fixtures/junit.xml fixtures/coverage/cobertura.xml fixtures/sbom.cdx.json fixtures/scan.sarif; do
  [ -s "$f" ] || fail "$f is missing or empty"
done

cases=$(grep -c '<testcase ' fixtures/junit.xml)
[ "$cases" -ge 1 ] || fail "junit.xml has no test cases"
grep -q '<failure' fixtures/junit.xml && fail "junit.xml contains a failure"
ok "junit.xml has $cases passing test cases"

grep -q '<coverage line-rate="' fixtures/coverage/cobertura.xml || fail "cobertura.xml has no line-rate"
ok "cobertura.xml has a line rate"

grep -q '"bomFormat": "CycloneDX"' fixtures/sbom.cdx.json || fail "sbom.cdx.json is not CycloneDX"
components=$(grep -c '"purl":' fixtures/sbom.cdx.json)
[ "$components" -ge 2 ] || fail "sbom.cdx.json lists fewer than 2 components"
ok "sbom.cdx.json lists $components components"

grep -q '"version": "2.1.0"' fixtures/scan.sarif || fail "scan.sarif is not SARIF 2.1.0"
results=$(grep -c '"ruleId":' fixtures/scan.sarif)
[ "$results" -eq 2 ] || fail "scan.sarif should have 2 results, found $results"
grep -q '"level": "error"' fixtures/scan.sarif && fail "scan.sarif has a high severity result"
ok "scan.sarif has $results low severity results"

echo "All fixtures are valid."
