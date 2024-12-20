#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOTDIR=$(realpath $SCRIPTDIR/..)
source $ROOTDIR/properties

#get gitops templates
REPO="${GITOPS_REPO:-https://github.com/redhat-ai-dev/ai-lab-app}"
BRANCH="${GITOPS_BRANCH:-main}"
REPONAME=$(basename $REPO)

TEMPDIR=$ROOTDIR/temp
rm -rf $TEMPDIR # clean up
mkdir -p $TEMPDIR
cd $TEMPDIR
git clone $REPO 2>&1 > /dev/null
(cd $REPONAME; git checkout $BRANCH; git pull)


DEST=$ROOTDIR/skeleton/gitops-template
rm -rf $DEST/components
rm -rf $DEST/app-of-apps
rm -rf $DEST/application.yaml
mkdir -p $DEST/components
mkdir -p $DEST/app-of-apps
cp -r $TEMPDIR/$REPONAME/templates/app-of-apps $DEST/
cp -r $TEMPDIR/$REPONAME/templates/http $DEST/components/http     # only support http now
cp -r $TEMPDIR/$REPONAME/templates/application.yaml $DEST/

# copy readme to techdoc folder
cp -r $TEMPDIR/$REPONAME/README.md $ROOTDIR/skeleton/techdoc/docs/gitops-application.md
sed -i "s/{{/\${{ /g" $ROOTDIR/skeleton/techdoc/docs/gitops-application.md
sed -i "s/}}/ }}/g" $ROOTDIR/skeleton/techdoc/docs/gitops-application.md
rm -rf $TEMPDIR

# replace {{value}} to ${{ value }} for software templates
sed -i "s/{{/\${{ /g" $DEST/application.yaml
sed -i "s/}}/ }}/g" $DEST/application.yaml

function iterate() {
  local dir="$1"

  for file in "$dir"/*; do
    if [ -f "$file" ]; then
      sed -i "s/{{/\${{ /g" $file
      sed -i "s/}}/ }}/g" $file
    fi

    if [ -d "$file" ]; then
      iterate "$file"
    fi
  done
}

iterate $DEST/components
iterate $DEST/app-of-apps