#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes 'gh' is in the path and the env vars used here have been exported as set

export GH_TOKEN=$GITHUB_TOKEN
export GH_REPO="github.com/$GITHUB_ORG_NAME/$APP_NAME"

gh auth login -p https
gh auth setup-git --hostname=github.com