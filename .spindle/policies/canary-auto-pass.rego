# Release policy for the canary environment.
#
# Approves a deployment to `canary` from the canary workflow when the newest
# trusted JUnit test results attestation for the deployment's commit passed.
# The report job in .github/workflows/canary.yml sends that attestation (the
# report action turns fixtures/junit.xml into a `test-results` attestation
# named `junit`) before the deploy-canary job starts.

# METADATA
# title: "Canary auto-pass"
# description: "Approves canary deployments when the JUnit test results attestation for the commit passed."
# custom:
#   spindle:
#     format: 1
#     mode: "enforce"
#     bindings:
#       - environment: "canary"
#         workflow: "canary.yml"
package spindle.policy

attestations_readable if is_array(input.attestations)

# Attestations arrive oldest first, so the last match is the newest.
junit := [a |
	some a in input.attestations
	a.kind == "test-results"
	a.name == "junit"
	a.trusted == true
]

latest := junit[count(junit) - 1]

counts := sprintf("%v passed, %v failed, %v errors", [
	object.get(latest, ["data", "passed"], "?"),
	object.get(latest, ["data", "failed"], "?"),
	object.get(latest, ["data", "errors"], "?"),
])

outcome := {"status": "error", "reason": "Prodgator could not read the attestations for this commit."} if {
	not attestations_readable
} else := {"status": "fail", "reason": "No trusted JUnit test results attestation for this commit. The canary report job must send fixtures/junit.xml before the deployment."} if {
	count(junit) == 0
} else := {"status": "pass", "reason": sprintf("JUnit test results passed (%v).", [counts])} if {
	latest.status == "pass"
} else := {"status": "fail", "reason": sprintf("JUnit test results did not pass: status %v (%v).", [latest.status, counts])}

results := [{
	"rule": "canary_tests_passed",
	"status": outcome.status,
	"blocking": true,
	"reason": outcome.reason,
	"evidence": {"junitAttestations": count(junit)},
}]
