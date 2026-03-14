# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A **composite GitHub Action** (`action.yml`) that deregisters AWS AMIs and deletes their associated EBS snapshots, filtered by `Application` and `Branch` tags.

## Repository Structure

- `action.yml` — Composite action entrypoint; defines all inputs and wires them to the shell script
- `scripts/cleanup-amis.sh` — Core logic: queries AMIs by tag, deregisters them, deletes snapshots

## Action Inputs

| Input | Required | Default |
|-------|----------|---------|
| `role_to_assume` | yes | — |
| `application_name` | yes | — |
| `branch_name` | yes | — |
| `aws_region` | no | `us-east-1` |

## How It Is Called

This action is consumed by other workflows using:

```yaml
uses: your-org/bk-cleanup-ami-workflow@main
with:
  role_to_assume: ${{ secrets.BK_ROLE_TO_ASSUME }}
  application_name: "${{ inputs.application_name }}"
  branch_name: "${{ needs.sanitize-branch.outputs.sanitized_branch }}"
```

## AMI Filtering

AMIs are filtered using two EC2 tags:
- `Application` → matched against `application_name` input
- `Branch` → matched against `branch_name` input

Only AMIs owned by the calling account (`--owners self`) are considered.

## Testing the Script Locally

```bash
export APPLICATION_NAME="my-app"
export BRANCH_NAME="feature-xyz"
bash scripts/cleanup-amis.sh
```

Requires AWS credentials in the environment (e.g., via `aws configure` or assumed role).
