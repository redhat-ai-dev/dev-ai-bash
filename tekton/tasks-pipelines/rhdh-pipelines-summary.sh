#!/usr/bin/env bash
set -o nounset
set -o pipefail

# uses quay.io/konflux-ci/appstudio-utils:ab6b0b8e40e440158e7288c73aff1cf83a2cc8a9@sha256:24179f0efd06c65d16868c2d7eb82573cce8e43533de6cea14fec3b7446e0b14
#TODO however registry.redhat.io/openshift4/ose-tools-rhel8:latest has jq so use that instead
# env vars from tekton task params

echo
echo "Build Summary:"
echo
echo "Build repository: $GIT_URL"
if [ "$BUILD_TASK_STATUS" == "Succeeded" ]; then
  echo "Generated Image is in : $IMAGE_URL"
fi
if [ -e "$SOURCE_BUILD_RESULT_FILE" ]; then
  url=$(jq -r ".image_url" <"$SOURCE_BUILD_RESULT_FILE")
  echo "Generated Source Image is in : $url"
fi
echo
echo End Summary