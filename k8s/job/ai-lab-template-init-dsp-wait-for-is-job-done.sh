#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

# Wait for the Image Stream creation job to finish
echo "Wait for the Image Stream job"
oc wait --for=condition=complete job/create-imagestream-${{ values.appName }}
echo "Done"

# Wait for the Namespace initialize job to finish
echo "Wait for the Namespace job"
oc wait --for=condition=complete job/initialize-namespace-${{ values.appName }}
echo "Done"
