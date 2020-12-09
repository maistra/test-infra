#!/bin/bash

set -eo pipefail

STATUS_DIR=${STATUS_DIR:-/status}
TIMEOUT=${TIMEOUT:-600}

function fail_on_timeout() {
  echo "ERROR: timed out while waiting for image build to finish. Please adjust TIMEOUT env variable (currently set to $TIMEOUT seconds) if you believe that will solve the problem."
  exit 1
}

# wait until image builder is finished
echo "INFO: waiting for status reported by image-builder in $STATUS_DIR"
(timeout "$TIMEOUT" inotifywait -e create,open --format '%f' --quiet "$STATUS_DIR" --monitor & )| while read -r i; do if [ "$i" == 'image_build_succeeded' ] || [ "$i" == 'image_build_failed' ]; then break; fi; done
## TODO handle timeout properly

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