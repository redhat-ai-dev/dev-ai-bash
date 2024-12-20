#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

exists=$(oc get secret pipelines-as-code-secret -n "$APP_NAMESPACE")
return_code=$?
if [ $return_code == 0 ]; then
  oc -n "$APP_NAMESPACE" delete secret pipelines-as-code-secret || exit
  sleep 1
fi

# TODO kludge since we cannot get multi-line values.yaml to configmap key/value so that we do not lose our newlines
# tried server of the ': |' and ': |-' and ': |+' and toYaml and indent and double curly bracket plus hyphen derivatives
GITHUB_APP_PRIVATE_KEY=$(echo "$GITHUB_APP_PRIVATE_KEY" | sed 's/-----BEGIN RSA PRIVATE KEY-----/55555/g' ) # notsecret
GITHUB_APP_PRIVATE_KEY=$(echo "$GITHUB_APP_PRIVATE_KEY" | sed 's/-----END RSA PRIVATE KEY-----/66666/g' ) # notsecret
GITHUB_APP_PRIVATE_KEY=$(echo "$GITHUB_APP_PRIVATE_KEY" | sed 's/ /\n/g' )
GITHUB_APP_PRIVATE_KEY=$(echo "$GITHUB_APP_PRIVATE_KEY" | sed 's/55555/-----BEGIN RSA PRIVATE KEY-----/g' ) # notsecret
GITHUB_APP_PRIVATE_KEY=$(echo "$GITHUB_APP_PRIVATE_KEY" | sed 's/66666/-----END RSA PRIVATE KEY-----/g' ) # notsecret

oc -n "$APP_NAMESPACE" create secret generic pipelines-as-code-secret \
--from-literal github-application-id="$GITHUB_APP_APP_ID" \
--from-literal github-private-key="$GITHUB_APP_PRIVATE_KEY" \
--from-literal webhook.secret="$GITHUB_APP_WEBHOOK_SECRET"
