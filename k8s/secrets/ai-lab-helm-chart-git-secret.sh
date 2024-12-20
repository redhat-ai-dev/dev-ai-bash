#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

exists=$(oc get secret "$GIT_SECRET_NAME" -n "$APP_NAMESPACE")
return_code=$?
if [ $return_code == 0 ]; then
  oc -n "$APP_NAMESPACE" delete secret "$GIT_SECRET_NAME" || exit
  sleep 1
fi
oc -n "$APP_NAMESPACE" create secret generic "$GIT_SECRET_NAME" --from-literal="$GIT_TOKEN_KEY"="$GIT_TOKEN" --type=kubernetes.io/basic-auth

