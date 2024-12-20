#!/usr/bin/env bash
set -o nounset
set -o pipefail


# uses registry.access.redhat.com/ubi9/skopeo:9.4-12
# of course env vars come from tekton task params

echo "Build Initialize: $IMAGE_URL"
echo

echo "Determine if Image Already Exists"
# Build the image when rebuild is set to true or image does not exist
# The image check comes last to avoid unnecessary, slow API calls
if [ "$REBUILD" == "true" ] || [ "$SKIP_CHECKS" == "false" ] || ! skopeo inspect --raw docker://$IMAGE_URL &>/dev/null; then
  echo -n "true" > $(results.build.path)
else
  echo -n "false" > $(results.build.path)
fi