#!/bin/sh
# Usage: wait-for-check.sh <pr-number> <pass|fail> <timeout-seconds>
# Polls `gh pr checks` until the check whose name matches $CHECK_PATTERN
# (case-insensitive extended regex) reaches the wanted bucket. Exits 1 on
# timeout, or when waiting for a failure and the check passes instead.
set -eu

pr="$1"; want="$2"; timeout="$3"
pattern="${CHECK_PATTERN:-prodgator.*polic}"
deadline=$(( $(date +%s) + timeout ))
last=""

while :; do
  # bucket is one of pass, fail, pending, skipping, cancel.
  line=$(gh pr checks "$pr" --json name,bucket --jq '.[] | "\(.bucket)|\(.name)"' 2>/dev/null \
    | grep -i -E "^[a-z]+\|.*${pattern}" | head -n 1 || true)
  bucket="${line%%|*}"
  name="${line#*|}"

  if [ "$line" != "$last" ]; then
    if [ -n "$line" ]; then
      echo "PR #${pr}: check \"${name}\" is ${bucket}"
    else
      echo "PR #${pr}: no check matching /${pattern}/ yet"
    fi
    last="$line"
  fi

  if [ -n "$line" ] && [ "$bucket" = "$want" ]; then
    echo "PR #${pr}: check \"${name}\" reported ${want} as expected."
    exit 0
  fi
  # Waiting for a failure: a pass means the policy did not block the PR.
  # Waiting for a pass: the old failure can linger until the check reruns
  # after the label is added, so keep polling until the deadline.
  if [ "$want" = "fail" ] && [ "$bucket" = "pass" ]; then
    echo "::error::PR #${pr}: check \"${name}\" passed before the ready label was added, so the PR policy did not block the pull request."
    exit 1
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "::error::PR #${pr}: timed out after ${timeout}s waiting for a check matching /${pattern}/ to report ${want} (last seen: ${line:-none})."
    exit 1
  fi
  sleep 15
done
