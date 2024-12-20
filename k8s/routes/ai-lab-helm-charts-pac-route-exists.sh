#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

until oc get route -n "$APP_NAMESPACE" pipelines-as-code-controller; do
  sleep 3
done
echo "Pipelines OK"

