#!/bin/bash

set -euo pipefail

VERSION="${BUILDER_VERSION:?BUILDER_VERSION must be set}"
SOURCE_REPO="${SOURCE_REPO:?SOURCE_REPO must be set}"
SOURCE_REF="${SOURCE_REF:?SOURCE_REF must be set}"

export CONTAINER_CLI=docker
export HUB=quay.io/maistra-dev

# Clone the PR source repo and check out the exact commit to build.
# SOURCE_REPO is the clone URL of the PR head repo (could be a fork).
# SOURCE_REF is the PR head SHA.
git clone "${SOURCE_REPO}" /tmp/source
cd /tmp/source
git checkout "${SOURCE_REF}"
make "build-containers-${VERSION}"
echo "Build validation passed for maistra-builder:${VERSION}"
