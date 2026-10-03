package prodgator.policy_test

import data.prodgator.policy

junit(status, trusted) := {
	"kind": "test-results",
	"name": "junit",
	"status": status,
	"trusted": trusted,
	"data": {"passed": 4, "failed": 0, "skipped": 0, "errors": 0},
}

release(attestations) := {"version": "prodgator.input/v1", "subject": "release", "attestations": attestations}

test_passing_junit_approves if {
	r := policy.results[0] with input as release([junit("pass", true)])
	r.status == "pass"
	r.blocking == true
	contains(r.reason, "4 passed")
}

test_failing_junit_fails if {
	r := policy.results[0] with input as release([junit("fail", true)])
	r.status == "fail"
	contains(r.reason, "status fail")
}

test_missing_junit_fails if {
	r := policy.results[0] with input as release([{"kind": "coverage", "name": "canary-coverage", "status": "pass", "trusted": true, "data": {}}])
	r.status == "fail"
	contains(r.reason, "No trusted JUnit")
}

test_untrusted_junit_does_not_count if {
	r := policy.results[0] with input as release([junit("pass", false)])
	r.status == "fail"
}

test_newest_junit_decides if {
	r := policy.results[0] with input as release([junit("fail", true), junit("pass", true)])
	r.status == "pass"
}

test_unreadable_attestations_error if {
	r := policy.results[0] with input as release(null)
	r.status == "error"
}
