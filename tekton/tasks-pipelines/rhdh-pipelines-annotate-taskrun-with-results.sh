#!/usr/bin/env bash
set -o nounset
set -o pipefail

# uses registry.redhat.io/openshift4/ose-cli:4.13
# env vars from tekton task params

# When this task is used in a pipelineRun triggered by Pipelines as Code, the annotations will be cleared,
# so we're re-adding them here
oc annotate taskrun $(context.taskRun.name) task.results.format=application/text
oc annotate taskrun $(context.taskRun.name) task.results.key=LINK_TO_SBOM
oc annotate taskrun $(context.taskRun.name) task.output.location=results
