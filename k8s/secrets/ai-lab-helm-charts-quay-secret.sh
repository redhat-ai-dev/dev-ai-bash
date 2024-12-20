#!/usr/bin/env bash
set -o nounset
set -o pipefail
  
# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

cd /tmp || exit

echo $QUAY_CONFIG_JSON > /tmp/config.json || exit
exists=$(oc get secret "$QUAY_SECRET_NAME" -n "$APP_NAMESPACE")
return_code=$?
if [ $return_code == 0 ]; then
oc -n "$APP_NAMESPACE" delete secret "$QUAY_SECRET_NAME" || exit
sleep 1
fi
oc -n "$APP_NAMESPACE" create secret docker-registry "$QUAY_SECRET_NAME" --from-file=.dockerconfigjson='/tmp/config.json' || exit

oc secrets link pipeline "$QUAY_SECRET_NAME" --for=pull,mount || exit
oc secrets link default "$QUAY_SECRET_NAME" --for=pull,mount || exit
