#!/usr/bin/env bash
set -o nounset
set -o pipefail

# pipeline currently uses registry.access.redhat.com/ubi9/buildah which is "OK" but if there is not a registry.redhat.io version, instead should use
# registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag where we add a wget of yq if necessary
# of course env vars are in fact tekton params so set in that case

if test -f /gitops-auth-secret/password ; then
  gitops_repo_url=${PARAM_GITOPS_REPO_URL%'.git'}
  remote_without_protocol=${gitops_repo_url#'https://'}
  password=$(cat /gitops-auth-secret/password)
  if test -f /gitops-auth-secret/username ; then
    username=$(cat /gitops-auth-secret/username)
    echo "https://${username}:${password})@${hostname}" > "${HOME}/.git-credentials"
    origin_with_auth=https://${username}:${password}@${remote_without_protocol}.git
  else
    origin_with_auth=https://${password}@${remote_without_protocol}.git
  fi
else
  echo "git credentials to push into gitops repository ${PARAM_GITOPS_REPO_URL} is not configured."
  echo "gitops repository is not updated automatically."
  echo "You can update gitops repository with the new image: ${PARAM_IMAGE} manually"
  echo "TODO: configure git credentials to update gitops repository."
  exit 0
fi

#TODO move down to follow git clone and then like in ai-lab-hel-charts setup pull email from git log information
git config --global user.email "redhat-ai-dev@noreply.com"
#TODO change to username from credentials
git config --global user.name "gitops-update"

git clone ${PARAM_GITOPS_REPO_URL}
gitops_repo_name=$(basename ${gitops_repo_url})
cd ${gitops_repo_name}

component_name=$(yq .metadata.name application.yaml)
deployment_patch_filepath="components/${component_name}/overlays/development/deployment-patch.yaml"
IMAGE_PATH='.spec.template.spec.containers[0].image'
old_image=$(yq "${IMAGE_PATH}" "${deployment_patch_filepath}")
yq e -i "${IMAGE_PATH} |= \"${PARAM_IMAGE}\"" "${deployment_patch_filepath}"

git add .
git commit -m "Update '${component_name}' component image to: ${PARAM_IMAGE}"
git remote set-url origin $origin_with_auth
git push 2> /dev/null || \
{
  echo "Failed to push update to gitops repository: ${PARAM_GITOPS_REPO_URL}"
  echo 'Do you have correct git credentials configured?'
  exit 1
}
echo "Successfully updated development image from ${old_image} to ${PARAM_IMAGE}"