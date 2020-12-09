#!/bin/bash

set -e

STATUS_DIR=${STATUS_DIR:-/status}
mkdir -p "$STATUS_DIR"

function create_err_status {
  echo "ERROR: failed building images"
  touch "${STATUS_DIR}"/image_build_failed
}

trap create_err_status ERR

export IKE_IMAGE_TAG="PR-${PULL_NUMBER}"

export GOBIN="${GOPATH}/bin"
export GOROOT=/usr/lib/golang/
export PATH="${PATH}:${GOPATH}/bin"

podman login -u="$QUAY_USER" -p="$QUAY_PWD" quay.io

make deps tools

make docker-build docker-push-versioned
make docker-build-test docker-push-test
IKE_TEST_PREPARED_NAME="prepared-image" make docker-build-test-prepared docker-push-test-prepared
IKE_TEST_PREPARED_NAME="image-prepared" make docker-build-test-prepared docker-push-test-prepared

touch "$STATUS_DIR/image_build_succeeded"
