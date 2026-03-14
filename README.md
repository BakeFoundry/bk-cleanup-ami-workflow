# bk-cleanup-ami-workflow

A composite GitHub Action that deregisters AWS AMIs and deletes their associated EBS snapshots for a given application and branch. Designed to be called from other workflows to clean up AMIs created during feature branch builds.

## How It Works

1. Assumes the provided AWS IAM role via OIDC
2. Queries EC2 for AMIs owned by the account, filtered by `Application` and `Branch` tags
3. For each matching AMI:
   - Collects associated EBS snapshot IDs
   - Deregisters the AMI
   - Deletes each associated snapshot

## Prerequisites

- AMIs must be tagged with `Application` and `Branch` tags at creation time
- The calling workflow must have OIDC permissions configured to allow assuming `role_to_assume`
- The assumed role must have the following IAM permissions:
  ```json
  {
    "Effect": "Allow",
    "Action": [
      "ec2:DescribeImages",
      "ec2:DeregisterImage",
      "ec2:DeleteSnapshot"
    ],
    "Resource": "*"
  }
  ```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `role_to_assume` | yes | — | AWS IAM role ARN to assume (via OIDC) |
| `application_name` | yes | — | Value of the `Application` tag on AMIs to target |
| `branch_name` | yes | — | Value of the `Branch` tag on AMIs to target |
| `aws_region` | no | `us-east-1` | AWS region where AMIs are located |

## Usage

### Basic Usage

```yaml
steps:
  - uses: your-org/bk-cleanup-ami-workflow@main
    with:
      role_to_assume: ${{ secrets.BK_ROLE_TO_ASSUME }}
      application_name: "my-app"
      branch_name: "feature-my-branch"
```

### With Branch Sanitization (typical pattern)

```yaml
jobs:
  sanitize-branch:
    runs-on: ubuntu-latest
    outputs:
      sanitized_branch: ${{ steps.sanitize.outputs.sanitized_branch }}
    steps:
      - id: sanitize
        shell: bash
        run: |
          BRANCH="${{ github.ref_name }}"
          echo "sanitized_branch=${BRANCH//\//-}" >> "$GITHUB_OUTPUT"

  cleanup-ami:
    needs: sanitize-branch
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: your-org/bk-cleanup-ami-workflow@main
        with:
          role_to_assume: ${{ secrets.BK_ROLE_TO_ASSUME }}
          application_name: "${{ inputs.application_name }}"
          branch_name: "${{ needs.sanitize-branch.outputs.sanitized_branch }}"
```

## Required Secret

| Secret | Description |
|--------|-------------|
| `BK_ROLE_TO_ASSUME` | Full ARN of the IAM role to assume, e.g. `arn:aws:iam::123456789012:role/my-cleanup-role` |

## Local Testing

You can run the cleanup script locally with AWS credentials already configured:

```bash
export APPLICATION_NAME="my-app"
export BRANCH_NAME="feature-my-branch"
bash scripts/cleanup-amis.sh
```
