package spindle.policy_test

import data.spindle.policy

pr(labels) := {"version": "spindle.input/v1", "subject": "pull_request", "labels": labels}

test_ready_label_passes if {
	r := policy.results[0] with input as pr(["ready", "docs"])
	r.status == "pass"
}

test_no_ready_label_fails if {
	r := policy.results[0] with input as pr(["docs"])
	r.status == "fail"
	r.blocking == true
}

test_no_labels_fails if {
	r := policy.results[0] with input as pr([])
	r.status == "fail"
}

test_unreadable_labels_error if {
	r := policy.results[0] with input as pr(null)
	r.status == "error"
}

test_release_subject_errors if {
	r := policy.results[0] with input as {"subject": "release", "labels": ["ready"]}
	r.status == "error"
}
