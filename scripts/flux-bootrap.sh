#!/bin/sh

set -xe

. $(dirname $0)/flux-env.sh

flux bootstrap github \
  --owner=${GITHUB_USER} \
  --log-level debug \
  --repository=${GITHUB_REPO} \
  --branch=${BRANCH} \
  --personal \
  --read-write-key \
  --path=${CLUSTER_PATH}

#  --components-extra=image-reflector-controller,image-automation-controller \

#flux bootstrap github \
#  --owner=${GITHUB_USER} \
#  --log-level debug \
#  --repository=${GITHUB_REPO} \
#  --branch=${BRANCH} \
#  --personal \
#  --private=false \
#  --path=${CLUSTER_PATH}

