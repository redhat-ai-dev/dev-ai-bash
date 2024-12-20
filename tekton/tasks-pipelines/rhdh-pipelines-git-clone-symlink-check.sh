#!/usr/bin/env bash
set -o nounset
set -o pipefail

# pipeline currently uses quay.io/konflux-ci/git-clone but instead should use
# registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag
# of course env vars are in fact tekton params so set in that case



CHECKOUT_DIR="${WORKSPACE_OUTPUT_PATH}/${PARAM_SUBDIRECTORY}"
check_symlinks() {
  FOUND_SYMLINK_POINTING_OUTSIDE_OF_REPO=false
  while read symlink
  do
    target=$(readlink -m "$symlink")
    if ! [[ "$target" =~ ^$CHECKOUT_DIR ]]; then
      echo "The cloned repository contains symlink pointing outside of the cloned repository: $symlink"
      FOUND_SYMLINK_POINTING_OUTSIDE_OF_REPO=true
    fi
  done < <(find $CHECKOUT_DIR -type l -print)
  if [ "$FOUND_SYMLINK_POINTING_OUTSIDE_OF_REPO" = true ] ; then
    return 1
  fi
}

if [ "${PARAM_ENABLE_SYMLINK_CHECK}" = "true" ] ; then
  echo "Running symlink check"
  check_symlinks
fi
