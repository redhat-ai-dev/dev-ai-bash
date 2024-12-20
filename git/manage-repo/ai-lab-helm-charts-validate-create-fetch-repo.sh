#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes 'gh' is in the path and the env vars used here have been exported as set
# assumes ../setup-config/ai-lab-helm-charts-gh-auth.sh has been run

setup_data() {
   gh repo clone "$GITHUB_SOURCE_REPO" app-source -- --no-tags --branch="$GITHUB_DEFAULT_BRANCH" --single-branch
   gh repo clone "$GITHUB_TETKON_SOURCE_REPO" tekton-source -- --no-tags --single-branch
   gh repo clone "$GH_REPO" "$APP_NAME" -- --no-tags --branch="$GITHUB_DEFAULT_BRANCH" --single-branch

   mkdir -p "$APP_NAME"/.tekton

   # feels like could be parameterized
   cd tekton-source/pac/pipelineRuns/.tekton || exit
   sed -i 's@'"$TEKTON_FILE_APP_NAME_REPLACEMENT"'@'"$APP_NAME"'@g' docker-push.yaml
   sed -i 's@'"$TEKTON_FILE_APP_NAMESPACE_REPLACEMENT"'@'"$APP_NAMESPACE"'@g' docker-push.yaml
   sed -i 's@'"$TEKTON_FILE_QUAY_ACCOUNT_REPLACEMENT"'@'"$QUAY_ACCOUNT_NAME"'@g' docker-push.yaml
   cd - || exit

   # feels like could be parameterized
   cd app-source/chatbot || exit
   cp * ../../"$APP_NAME"
   cd ../../tekton-source/pac/pipelineRuns/.tekton || exit
   cp docker-push.yaml ../../../../"$APP_NAME"/.tekton
   cd ../../../../"$APP_NAME" || exit
}



export HOME=/tmp
cd /tmp || exit

gh repo view "$GH_REPO" --json id 2> /dev/null

return_code=$?

if [ $return_code == 0 ]; then
  echo Repo "$GH_REPO" already exists, checking if contents are OK
  setup_data
  cd $HOME || exit
  gh repo clone "$GH_REPO" existing -- --no-tags --branch="$GITHUB_DEFAULT_BRANCH" --single-branch || exit

  # easily an arg or exported env var
  FILES=("Containerfile"
  "chatbot_ui.py"
  "requirements.txt"
  ".tekton/docker-push.yaml")

  for FILE in "${FILES[@]}"
  do
    echo Looking at "${FILE}"
    same=$(diff existing/"${FILE}" "$APP_NAME"/"${FILE}")
    return_code=$?
    if [ $return_code != 0 ]; then
      echo "$same"
      exit 1
    fi
  done

  echo Repo "$GH_REPO" contents OK, exiting.
  exit 0
else
  gh repo create "$GH_REPO" --public --gitignore Python --license Apache-2.0 || exit
  gh repo view "$GH_REPO" --json id 2> /dev/null
  return_code=$?
  if [ $return_code != 0 ]; then
    echo Repo create of "$GH_REPO" could not be confirmed
    exit $return_code
  fi
fi
