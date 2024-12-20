#!/usr/bin/env bash
set -o nounset
set -o pipefail

# uses registry.redhat.io/rhtas-tech-preview/cosign-rhel9@sha256:151f4a1e721b644bafe47bf5bfb8844ff27b95ca098cc37f3f6cbedcda79a897
#TODO see if other use of cosign from Jobs etc can leverage this image vs. wget'ing cosign
# env vars from tekton task params

status=-1
max_try=5
wait_sec=2
for run in $(seq 1 $max_try); do
  status=0
  cosign download sbom $IMAGE_URL 2>>err
  status=$?
  if [ "$status" -eq 0 ]; then
    break
  fi
  sleep $wait_sec
done
if [ "$status" -ne 0 ]; then
    echo "Failed to get SBOM after ${max_try} tries" >&2
    cat err >&2
fi

# This result will be ignored by RHDH, but having it set is actually necessary for the task to be properly
# identified. For now, we're adding the image URL to the result so it won't be empty.
echo -n "$IMAGE_URL" > $(results.LINK_TO_SBOM.path)
