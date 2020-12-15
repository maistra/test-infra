#!/bin/bash

set -eo pipefail

STATUS_DIR=${STATUS_DIR:-/status}
TIMEOUT=${TIMEOUT:-900}

function fail_on_timeout() {
  EXIT_CODE=$?
  if [ $EXIT_CODE == 124 ]; then
    echo "ERROR: timed out while waiting for image build to finish. Please adjust TIMEOUT env variable (currently set to $TIMEOUT seconds) if you believe that will solve the problem."
  fi
  exit $EXIT_CODE
}

trap fail_on_timeout ERR

# wait until image builder is finished
echo "INFO: waiting for status reported by image-builder in $STATUS_DIR"
# shellcheck disable=SC2016
WAIT_CMD='inotifywait -e create,open --format "%f" --quiet "${STATUS_DIR}" --monitor | while read -r i; do if [ "$i" == "image_build_succeeded" ] || [ "$i" == "image_build_failed" ]; then break; fi; done'
STATUS_DIR="${STATUS_DIR}" timeout --signal HUP "$TIMEOUT" bash -c "${WAIT_CMD}"

if [[ -f "$STATUS_DIR/image_build_failed" ]]; then
  echo "ERROR: precondition: image build failed."
  exit 1
fi

export IKE_IMAGE_TAG="PR-${PULL_NUMBER}"

export GOBIN="${GOPATH}/bin"
export GOROOT=/usr/lib/golang/
export PATH="${PATH}:${GOPATH}/bin"

oc login "${IKE_CLUSTER_ADDRESS}" -u "${IKE_CLUSTER_USER}" -p "${IKE_CLUSTER_PWD}" --insecure-skip-tls-verify=true

make deps tools test-e2e