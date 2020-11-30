#!/bin/bash

set -e

export IKE_IMAGE_TAG="PR-${PULL_NUMBER}"

mkdir -p /work/workspace && cd /work/workspace

export GOPATH="$(pwd)/"
export GOBIN="${GOPATH}/bin"
export GOROOT=/usr/lib/golang/
export PATH="${PATH}:${GOBIN}"

mkdir -p "${GOPATH}"/src/github.com/"${REPO_OWNER}"/
cd "${GOPATH}"/src/github.com/"${REPO_OWNER}"/

git clone --depth 1 https://github.com/"${REPO_OWNER}"/"${REPO_NAME}".git && cd "${REPO_NAME}"
git pr "${PULL_NUMBER}"

oc login "${IKE_CLUSTER_ADDRESS}" -u "${IKE_CLUSTER_USER}" -p "${IKE_CLUSTER_PWD}" --insecure-skip-tls-verify=true

make deps tools test-e2e
