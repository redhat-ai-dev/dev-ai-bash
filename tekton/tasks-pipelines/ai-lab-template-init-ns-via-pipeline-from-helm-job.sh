#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible
# CONFIGURE_PIPELINE is substitute for ... why not a conditional helm substitution ??
#TODO also, do we need a Job creating a pipeline .... need to clarify the extra hops

          NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
          echo "Initialize RHDH Namespace: $NS"
          cat <<CONFIGURE_PIPELINE | oc create -f -
          apiVersion: tekton.dev/v1
          kind: PipelineRun
          metadata:
            generateName: dev-namespace-setup-
            namespace: $NS
          spec:
            pipelineSpec:
              tasks:
                - name: configure-namespace
                  taskRef:
                    kind: Task
                    params:
                      - name: kind
                        value: task
                      - name: name
                        value: dev-namespace-setup
                      - name: namespace
                        value: ${{ values.rhdhNamespace }}
                    resolver: cluster
          CONFIGURE_PIPELINE
