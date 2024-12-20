#!/usr/bin/env bash
set -o nounset
set -o pipefail

# pipeline currently uses quay.io/konflux-ci/git-clone but instead should use
# registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag where we add a wget of yq if necessary
# konflux-ci/git-clone i.e. https://github.com/konflux-ci/git-clone uses git submodules :-) to bring in
# https://github.com/tektoncd-catalog/git-clone which accesses chainguard images for among other things ko-app/git-init
# since most of the Googlers who did ko are now at chainguard
# of course env vars are in fact tekton params so set in that case

# ca is mounted via volume mount to /mnt/trusted-ca but if we leverage workspace there is more flexibility, including conditional execution

set -eu
if [ "${PARAM_VERBOSE}" = "true" ] ; then
  set -x
fi

if [ -n "${PARAM_GIT_INIT_IMAGE}" ]; then
  echo "WARNING: provided deprecated gitInitImage parameter has no effect."
fi

if [ "${WORKSPACE_BASIC_AUTH_DIRECTORY_BOUND}" = "true" ] ; then
  if [ -f "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.git-credentials" ] && [ -f "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.gitconfig" ]; then
    cp "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.git-credentials" "${PARAM_USER_HOME}/.git-credentials"
    cp "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/.gitconfig" "${PARAM_USER_HOME}/.gitconfig"
  # Compatibility with kubernetes.io/basic-auth secrets
  elif [ -f "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/username" ] && [ -f "${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/password" ]; then
    HOSTNAME=$(echo $PARAM_URL | awk -F/ '{print $3}')
    echo "https://$(cat ${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/username):$(cat ${WORKSPACE_BASIC_AUTH_DIRECTORY_PATH}/password)@$HOSTNAME" > "${PARAM_USER_HOME}/.git-credentials"
    echo -e "[credential \"https://$HOSTNAME\"]\n  helper = store" > "${PARAM_USER_HOME}/.gitconfig"
  else
    echo "Unknown basic-auth workspace format"
    exit 1
  fi
  chmod 400 "${PARAM_USER_HOME}/.git-credentials"
  chmod 400 "${PARAM_USER_HOME}/.gitconfig"
fi

# Should be called after the gitconfig is copied from the repository secret
ca_bundle=/mnt/trusted-ca/ca-bundle.crt
if [ -f "$ca_bundle" ]; then
  echo "INFO: Using mounted CA bundle: $ca_bundle"
  git config --global http.sslCAInfo "$ca_bundle"
fi

if [ "${WORKSPACE_SSH_DIRECTORY_BOUND}" = "true" ] ; then
  cp -R "${WORKSPACE_SSH_DIRECTORY_PATH}" "${PARAM_USER_HOME}"/.ssh
  chmod 700 "${PARAM_USER_HOME}"/.ssh
  chmod -R 400 "${PARAM_USER_HOME}"/.ssh/*
fi

CHECKOUT_DIR="${WORKSPACE_OUTPUT_PATH}/${PARAM_SUBDIRECTORY}"

cleandir() {
  # Delete any existing contents of the repo directory if it exists.
  #
  # We don't just "rm -rf ${CHECKOUT_DIR}" because ${CHECKOUT_DIR} might be "/"
  # or the root of a mounted volume.
  if [ -d "${CHECKOUT_DIR}" ] ; then
    # Delete non-hidden files and directories
    rm -rf "${CHECKOUT_DIR:?}"/*
    # Delete files and directories starting with . but excluding ..
    rm -rf "${CHECKOUT_DIR}"/.[!.]*
    # Delete files and directories starting with .. plus any other character
    rm -rf "${CHECKOUT_DIR}"/..?*
  fi
}

if [ "${PARAM_DELETE_EXISTING}" = "true" ] ; then
  cleandir
fi

test -z "${PARAM_HTTP_PROXY}" || export HTTP_PROXY="${PARAM_HTTP_PROXY}"
test -z "${PARAM_HTTPS_PROXY}" || export HTTPS_PROXY="${PARAM_HTTPS_PROXY}"
test -z "${PARAM_NO_PROXY}" || export NO_PROXY="${PARAM_NO_PROXY}"

//TODO do we really need to worry about supporting the ko img bld framework ??
/ko-app/git-init \
  -url="${PARAM_URL}" \
  -revision="${PARAM_REVISION}" \
  -refspec="${PARAM_REFSPEC}" \
  -path="${CHECKOUT_DIR}" \
  -sslVerify="${PARAM_SSL_VERIFY}" \
  -submodules="${PARAM_SUBMODULES}" \
  -depth="${PARAM_DEPTH}" \
  -sparseCheckoutDirectories="${PARAM_SPARSE_CHECKOUT_DIRECTORIES}"
cd "${CHECKOUT_DIR}"
RESULT_SHA="$(git rev-parse HEAD)"
EXIT_CODE="$?"
if [ "${EXIT_CODE}" != 0 ] ; then
  exit "${EXIT_CODE}"
fi
printf "%s" "${RESULT_SHA}" > "$(results.commit.path)"
printf "%s" "${PARAM_URL}" > "$(results.url.path)"
printf "%s" "$(git log -1 --pretty=%ct)" > "$(results.commit-timestamp.path)"

if [ "${PARAM_FETCH_TAGS}" = "true" ] ; then
  echo "Fetching tags"
  git fetch --tags
fi