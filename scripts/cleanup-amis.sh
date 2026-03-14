#!/usr/bin/env bash
set -euo pipefail

: "${APPLICATION_NAME:?APPLICATION_NAME is required}"
: "${BRANCH_NAME:?BRANCH_NAME is required}"

echo "==> Searching for AMIs with Application='${APPLICATION_NAME}' and Branch='${BRANCH_NAME}'"

AMI_IDS=$(aws ec2 describe-images \
  --owners self \
  --filters \
    "Name=tag:Application,Values=${APPLICATION_NAME}" \
    "Name=tag:Branch,Values=${BRANCH_NAME}" \
  --query 'Images[*].ImageId' \
  --output text)

if [[ -z "${AMI_IDS}" ]]; then
  echo "No AMIs found for Application='${APPLICATION_NAME}' Branch='${BRANCH_NAME}'. Nothing to clean up."
  exit 0
fi

echo "Found AMIs: ${AMI_IDS}"

for AMI_ID in ${AMI_IDS}; do
  echo "---"
  echo "Processing AMI: ${AMI_ID}"

  # Collect associated snapshot IDs before deregistering
  SNAPSHOT_IDS=$(aws ec2 describe-images \
    --image-ids "${AMI_ID}" \
    --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' \
    --output text)

  echo "Deregistering AMI: ${AMI_ID}"
  aws ec2 deregister-image --image-id "${AMI_ID}"

  for SNAPSHOT_ID in ${SNAPSHOT_IDS}; do
    echo "Deleting snapshot: ${SNAPSHOT_ID}"
    aws ec2 delete-snapshot --snapshot-id "${SNAPSHOT_ID}"
  done
done

echo "==> Cleanup complete."
