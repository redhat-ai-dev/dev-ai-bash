#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# TODO change helm job in skeleton/gitops-template/components/http/base/rhoai/create-imagestream.yaml to use this image ^^
# instead of  quay.io/redhat-ai-dev/utils:latest

NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
oc wait -l statefulset=${{ values.name }}-notebook --for=condition=ready pod --timeout=300s
