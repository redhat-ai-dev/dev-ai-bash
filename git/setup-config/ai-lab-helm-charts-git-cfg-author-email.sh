#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes in a repo that you have cloned

author=$(git log -1 --pretty=format:"%aN")
email=$(git log -1 --pretty=format:"%ae")

git config user.email "$email"
git config user.name "$author"

