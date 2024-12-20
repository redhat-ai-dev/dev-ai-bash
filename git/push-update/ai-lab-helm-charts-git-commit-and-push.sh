#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes in a repo that you have cloned
# assumes env vars here have been exported and accessible
# assumes ../setup-config/ai-lab-helm-charts-git-cfg-author-emails.sh has been run

git status -s | awk '{ print $2 }' | xargs -l -r git add
git commit -a -m "Copy repo content"
git push origin "$GITHUB_DEFAULT_BRANCH"

