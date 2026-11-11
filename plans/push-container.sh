#!/bin/bash
set -euo pipefail

VERSION="${BUILDER_VERSION:?BUILDER_VERSION must be set}"
QUAY_USER="${QUAY_USER:?QUAY_USER must be set}"
QUAY_PASS="${QUAY_PASS:?QUAY_PASS must be set}"

# TMT clones the repo (git_url + git_ref from the workflow) and makes it
# available at TMT_TREE. The script runs from a different directory by default,
# so we cd to TMT_TREE where the Makefile and docker/ directory live.
# See: https://tmt.readthedocs.io/en/stable/overview.html (Step Variables)
ROOT_REPO="${TMT_TREE:?TMT_TREE must be set by TMT}"

export CONTAINER_CLI=docker
export HUB=quay.io/maistra-dev

cd "${ROOT_REPO}"

echo "${QUAY_PASS}" | docker login -u="${QUAY_USER}" --password-stdin quay.io

# Build and push all supported architectures.
make "maistra-builder_${VERSION}.push_multi"

echo "Push completed for maistra-builder:${VERSION} (multi-arch)"
