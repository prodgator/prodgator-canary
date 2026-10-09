# prodgator-canary (GitHub)

A small repository that exercises Prodgator's GitHub integration on a schedule, so a broken webhook, report upload, findings import or deployment gate shows up within hours instead of when a customer notices. Everything in `fixtures/` is static test data. The findings in `fixtures/scan.sarif` are synthetic and point at `sample/hello.js`, which is never run.

The canaries report to the Prodgator development environment (`https://api.prodgator.dev`).

## What runs

### `canary.yml` (every 3 hours at :17 UTC, and on demand)

| Job | What it does |
|---|---|
| `test` | Runs `scripts/validate.sh` on the fixtures. |
| `build` | Writes `dist/canary-build.txt` and uploads it as a workflow artifact. |
| `report` | Always runs. Sends a report with `prodgator/prodgator-action` (pinned to v1.0.1): JUnit results from `fixtures/junit.xml`, line coverage from `fixtures/coverage/cobertura.xml`, the CycloneDX SBOM `fixtures/sbom.cdx.json`, the SARIF file `fixtures/scan.sarif` (two low severity synthetic findings with fixed fingerprints, so repeat runs update the same findings) and the build artifact. |
| `deploy-canary` | Deploys to the `canary` environment. The Prodgator protection rule holds it until the `Canary auto-pass` policy approves it. |
| `deploy-manual` | Only on a manual run with **manual_deploy** ticked. Deploys to `canary-manual`, which has the protection rule and no policy, so it waits for a person to approve it in Prodgator. |

What a healthy run shows in Prodgator: the run appears once, its report has the test results, coverage, SBOM and scan attestations and two artifacts, the two synthetic findings are open for this repository, and the `canary` deployment was approved by the policy.

### `pr-gate-canary.yml` (Mondays at 09:41 UTC, and on demand)

Opens a pull request from `canary/pr-<run id>`, waits up to 10 minutes for the **Prodgator policies** check to fail (the pull request has no `ready` label yet), adds the `ready` label (creating it if needed), waits up to 10 minutes for the check to pass, then closes the pull request and deletes the branch. The job fails with a log line naming the step if either transition does not happen.

## Run it by hand

Actions, pick the workflow, **Run workflow**. Or with the GitHub CLI:

```bash
gh workflow run canary.yml -R prodgator/prodgator-canary
gh workflow run canary.yml -R prodgator/prodgator-canary -f manual_deploy=true
gh workflow run pr-gate-canary.yml -R prodgator/prodgator-canary
```

## Policies

- `.prodgator/policies/canary-auto-pass.rego` is read by Prodgator on every push to `main` that changes that folder. It is an enforce release policy bound to the `canary` environment of this repository and the `canary.yml` workflow. It approves when the newest trusted JUnit test results attestation for the commit passed, and rejects otherwise. Its tests are in `canary-auto-pass_test.rego`.
- `policies/pull-request/canary-pr-ready.rego` passes a pull request only when it has the `ready` label. It sits outside `.prodgator/policies/` because a repository policy file cannot set "Used for: Pull requests" or hold a pull request binding yet. It is imported in Prodgator by hand (see below).

Run the policy tests locally with [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa):

```bash
opa test -v .prodgator/policies/
opa test -v policies/pull-request/
```

Anyone who can push to `main` can change the release policy, so protect `main` (and `.prodgator/policies/`) with branch protection and code owners.

## Setup

Done in code or by API:

- The Prodgator (dev) GitHub App is installed on this repository.
- GitHub environments `canary` and `canary-manual` exist, each with the Prodgator app as a custom deployment protection rule.
- The `Canary auto-pass` release policy comes from `.prodgator/policies/`.

Done by hand:

1. In Prodgator (Gates, Policies), import `policies/pull-request/canary-pr-ready.rego` with its test file, set **Used for** to Pull requests, and add a pull request binding for this repository with base branch `main`.
2. For `pr-gate-canary.yml`: allow GitHub Actions to create pull requests (organization Settings, Actions, General, Workflow permissions, "Allow GitHub Actions to create and approve pull requests", then the same setting on this repository).

Nothing is bound to `canary-manual` on purpose: with no policy, Prodgator leaves its protection rule waiting for a person, which is the manual approval path.

## Redeploys

The scheduled canary redeploys the head commit of `main`. Deployments to a protected environment need a recorded change for that commit, so the head has to be a commit that landed after change recording started. Last refreshed: 2026-10-09.
