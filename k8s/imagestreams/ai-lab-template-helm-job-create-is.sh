#!/usr/bin/env bash
set -o nounset
set -o pipefail

# assumes use of registry.redhat.io/openshift4/ose-cli-rhel9:v4.16 or later tag if run from k8s container
# TODO change helm job in skeleton/gitops-template/components/http/base/rhoai/create-imagestream.yaml to use this image ^^
# instead of  quay.io/redhat-ai-dev/utils:latest

# Check for image stream and create it not present
echo "Checking if the image stream exist"
if ! oc get is custom-sqlite3-odh-minimal-notebook-container -n redhat-ods-applications >/dev/null 2>&1 ; then
  echo "The image stream does not exist, a new image stream will be created"
  #TODO use 'oc create is <name> -n <namespace> ..' instead of oc apply yaml
  cat <<EOF | oc apply -f -
  kind: ImageStream
  apiVersion: image.openshift.io/v1
  metadata:
    # can recplace this yaml with 'oc annotate ...'
    annotations:
      opendatahub.io/notebook-image-name: custom-sqlite3-odh-minimal-notebook-container
      opendatahub.io/notebook-image-url: 'quay.io/redhat-ai-dev/odh-minimal-notebook-container:v2-2024a-20240523-sqlite3'
    name: custom-sqlite3-odh-minimal-notebook-container
    namespace: redhat-ods-applications
    #TODO can replace this yaml with 'oc label ...'
    labels:
      opendatahub.io/dashboard: 'true'
      opendatahub.io/notebook-image: 'true'
  spec:
    #TODO can replace this yaml with setting lookup policy with 'oc create is --lookup-local=true
    lookupPolicy:
      local: true
    #TODO can replace this yaml with 'oc tag'
    tags:
      - name: v2-2024a-20240523-sqlite3
        annotations:
          openshift.io/imported-from: 'quay.io/redhat-ai-dev/odh-minimal-notebook-container:v2-2024a-20240523-sqlite3'
        from:
          kind: DockerImage
          name: 'quay.io/redhat-ai-dev/odh-minimal-notebook-container:v2-2024a-20240523-sqlite3'
        generation: 2
        importPolicy:
          importMode: Legacy
        referencePolicy:
          type: Source
EOF
else
  echo "Image stream is already present, skipping create"
fi


##TODO replace above with'oc' built-ins
#$ oc help create is
#Create a new image stream.
#
# Image streams allow you to track, tag, and import images from other registries. They also define an access controlled
#destination that you can push images to. An image stream can reference images from many different registries and control
#how those images are referenced by pods, deployments, and builds.
#
# If --lookup-local is passed, the image stream will be used as the source when pods reference it by name. For example,
#if stream 'mysql' resolves local names, a pod that points to 'mysql:latest' will use the image the image stream points
#to under the "latest" tag.
#
#Aliases:
#imagestream, is
#
#Examples:
#  # Create a new image stream
#  oc create imagestream mysql
#
#Options:
#    --allow-missing-template-keys=true:
#	If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to
#	golang and jsonpath output formats.
#
#    --dry-run='none':
#	Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without
#	sending it. If server strategy, submit server-side request without persisting the resource.
#
#    --lookup-local=false:
#	If true, the image stream will be the source for any top-level image reference in this project.
#
#    -o, --output='':
#	Output format. One of: (json, yaml, name, go-template, go-template-file, template, templatefile, jsonpath,
#	jsonpath-as-json, jsonpath-file).
#
#    --save-config=false:
#	If true, the configuration of current object will be saved in its annotation. Otherwise, the annotation will
#	be unchanged. This flag is useful when you want to perform kubectl apply on this object in the future.
#
#    --show-managed-fields=false:
#	If true, keep the managedFields when printing objects in JSON or YAML format.
#
#    --template='':
#	Template string or path to template file to use when -o=go-template, -o=go-template-file. The template format
#	is golang templates [http://golang.org/pkg/text/template/#pkg-overview].
#
#Usage:
#  oc create imagestream NAME [flags] [options]
#
#Use "oc options" for a list of global command-line options (applies to all commands).

##TODO more replace with 'oc tags'
#$ oc help tag
#Tag existing images into image streams.
#
# The tag command allows you to take an existing tag or image from an image stream, or a container image pull spec, and
#set it as the most recent image for a tag in 1 or more other image streams. It is similar to the 'docker tag' command,
#but it operates on image streams instead.
#
# Pass the --insecure flag if your external registry does not have a valid HTTPS certificate, or is only served over
#HTTP. Pass --scheduled to have the server regularly check the tag for updates and import the latest version (which can
#then trigger builds and deployments). Note that --scheduled is only allowed for container images.
#
#Examples:
#  # Tag the current image for the image stream 'openshift/ruby' and tag '2.0' into the image stream 'yourproject/ruby
#with tag 'tip'
#  oc tag openshift/ruby:2.0 yourproject/ruby:tip
#
#  # Tag a specific image
#  oc tag openshift/ruby@sha256:6b646fa6bf5e5e4c7fa41056c27910e679c03ebe7f93e361e6515a9da7e258cc yourproject/ruby:tip
#
#  # Tag an external container image
#  oc tag --source=docker openshift/origin-control-plane:latest yourproject/ruby:tip
#
#  # Tag an external container image and request pullthrough for it
#  oc tag --source=docker openshift/origin-control-plane:latest yourproject/ruby:tip --reference-policy=local
#
#  # Remove the specified spec tag from an image stream
#  oc tag openshift/origin-control-plane:latest -d
#
#Options:
#    --alias=false:
#	Should the destination tag be updated whenever the source tag changes. Applies only to a single image stream.
#	Defaults to false.
#
#    -d, --delete=false:
#	Delete the provided spec tags.
#
#    --insecure=false:
#	Set to true if importing the specified container image requires HTTP or has a self-signed certificate.
#	Defaults to false.
#
#    --reference=false:
#	Should the destination tag continue to pull from the source namespace. Defaults to false.
#
#    --reference-policy='source':
#	Allow to request pullthrough for external image when set to 'local'. Defaults to 'source'.
#
#    --scheduled=false:
#	Set a container image to be periodically imported from a remote repository. Defaults to false.
#
#    --source='':
#	Optional hint for the source type; valid values are 'imagestreamtag', 'istag', 'imagestreamimage', 'isimage',
#	and 'docker'.
#
#Usage:
#  oc tag [--source=SOURCETYPE] SOURCE DEST [DEST ...] [flags] [options]
#
#Use "oc options" for a list of global command-line options (applies to all commands).