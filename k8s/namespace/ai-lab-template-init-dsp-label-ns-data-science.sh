#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

# Label the namespace as a DataScienceProject
NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
oc label ns $NS opendatahub.io/dashboard=true --overwrite
