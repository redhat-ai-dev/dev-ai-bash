#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container
# assumes env vars here have been exported and accessible

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR=$(realpath $SCRIPTDIR/..)
SKELETON_DIR=$ROOT_DIR/skeleton
TEMPLATE_DIR=$ROOT_DIR/templates

REPO="${SAMPLE_REPO:-https://github.com/redhat-ai-dev/ai-lab-samples}"
BRANCH="${SAMPLE_BRANCH:-main}"
DIRNAME=$(basename $REPO)

mkdir -p $SCRIPTDIR/samples
SAMPLE_DIR=$SCRIPTDIR/samples/$DIRNAME

if [ -d $SAMPLE_DIR ]; then
    (cd $SAMPLE_DIR; git pull 2>&1 > /dev/null)
else
    (cd $SCRIPTDIR/samples;  git clone $REPO 2>&1 > /dev/null)
fi

(cd $SAMPLE_DIR; git checkout $BRANCH; git pull)

cd $SAMPLE_DIR
# get readme to source component doc
cp -r $SAMPLE_DIR/README.md  $SKELETON_DIR/techdoc/docs/source-component.md

for f in */; do
    if [ -d "$f" ]; then
        # $f is a directory
        SAMPLENAME=$(basename $f)
        DEST=$ROOT_DIR/templates/$SAMPLENAME
        rm -rf $DEST
        mkdir -p $DEST
        cp -r $SAMPLE_DIR/$SAMPLENAME $DEST/content

        # add template card docs
        cp -r $ROOT_DIR/skeleton/template-card-techdocs/base/docs $DEST/docs
        cp -r $ROOT_DIR/skeleton/template-card-techdocs/base/mkdocs.yml $DEST/mkdocs.yml

        cp $ROOT_DIR/skeleton/template.yaml $DEST/template.yaml

        # get default env variables
        source $SCRIPTDIR/envs/base

        # get sample env variables
        source $SCRIPTDIR/envs/$SAMPLENAME

        if [ -f $f/Containerfile ]; then
            sed -i "s!sed.edit.DOCKERFILE!Containerfile!g" $DEST/template.yaml
            sed -i "s!sed.edit.BUILDCONTEXT!.!g" $DEST/template.yaml
        fi

        sed -i "s!sed.edit.APP_NAME!$APP_NAME!g" $DEST/template.yaml
        sed -i "s!sed.edit.APP_DISPLAY_NAME!$APP_DISPLAY_NAME!g" $DEST/template.yaml
        sed -i "s!sed.edit.DESCRIPTION!$APP_DESC!g" $DEST/template.yaml
        sed -i "s!sed.edit.APPTAGS!$APP_TAGS!g" $DEST/template.yaml
        sed -i "s!sed.edit.CATALOG_DESCRIPTION!Secure Supply Chain Example for $APP_DISPLAY_NAME!g" $DEST/template.yaml

        sed -i "s!sed.edit.APP_DISPLAY_NAME!$APP_DISPLAY_NAME!g" $DEST/docs/index.md
        sed -i "s!sed.edit.TEMPLATE_SOURCE_URL!$TEMPLATE_SOURCE_URL!g" $DEST/docs/index.md

        if [ $SUPPORT_LLM == false ]; then
            sed -i '/# SED_LLM_SERVER_START/,/# SED_LLM_SERVER_END/d' $DEST/template.yaml
        fi
        if [ $SUPPORT_ASR == false ]; then
            sed -i '/# SED_ASR_MODEL_SERVER_START/,/# SED_ASR_MODEL_SERVER_END/d' $DEST/template.yaml
        fi
        if [ $SUPPORT_DETR == false ]; then
            sed -i '/# SED_DETR_MODEL_SERVER_START/,/# SED_DETR_MODEL_SERVER_END/d' $DEST/template.yaml
        fi
        if [ $SUPPORT_DB == false ]; then
            sed -i '/# SED_DB_START/,/# SED_DB_END/d' $DEST/template.yaml
        fi

        source $ROOT_DIR/properties
        cat $DEST/template.yaml | envsubst > $DEST/new-template.yaml
        mv $DEST/new-template.yaml $DEST/template.yaml
    fi
done


rm -rf $SCRIPTDIR/samples