#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-docker-builder-rhel9:v4.16 or later tag if run from k8s container

cd /tmp || exit
wget https://github.com/cli/cli/releases/download/v"$GH_VERSION"/gh_"$GH_VERSION"_linux_amd64.tar.gz || exit
tar xzf gh_"$GH_VERSION"_linux_amd64.tar.gz
GH_PATH=$(pwd)/gh_"$GH_VERSION"_linux_amd64/bin
export PATH="$GH_PATH":"$PATH"