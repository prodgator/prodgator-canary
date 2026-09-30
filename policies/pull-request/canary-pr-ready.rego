# Pull request policy for the PR gate canary.
#
# Passes only when the pull request carries the `ready` label. The
# pr-gate-canary workflow opens a pull request without the label, expects
# the "Prodgator policies" check to fail, adds the label and expects it to
# pass.
#
# This file lives outside .prodgator/policies/ on purpose: policies read from
# that folder are release policies, and a repository file cannot yet set
# "Used for: Pull requests" or carry a pull request binding. Import this
# file in Prodgator (Gates, Policies, Import .rego), set Used for to Pull
# requests and bind it to this repository with base branch `main`.

# METADATA
# title: "Canary PR ready label"
# description: "Pull requests to main need the ready label."
# custom:
#   spindle:
#     format: 1
#     mode: "enforce"
package spindle.policy

labels_readable if is_array(input.labels)

has_ready if "ready" in input.labels

outcome := {"status": "error", "reason": "This policy only evaluates pull requests."} if {
	input.subject != "pull_request"
} else := {"status": "error", "reason": "Prodgator could not read the pull request labels."} if {
	not labels_readable
} else := {"status": "pass", "reason": "The pull request has the ready label."} if {
	has_ready
} else := {"status": "fail", "reason": "Add the ready label to this pull request."}

results := [{
	"rule": "ready_label",
	"status": outcome.status,
	"blocking": true,
	"reason": outcome.reason,
}]
