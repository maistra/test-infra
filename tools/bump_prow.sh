#!/bin/bash

# Copyright (C) 2020 Red Hat, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -u
set -o pipefail

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

function validate_args() {
  if [ $# -ne 1 ] || [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
    echo "Updates prow image references in cluster config"
    echo
    echo "Usage: ${0} <version>"
    echo
    echo "Where <version> is:"
    echo "  istio: Bump to whatever Istio master uses"
    echo "  upstream: Bump to whatever version kubernetes upstream master uses"
    echo "  Anything else: Uses it as the version. Note that prow versions are in the format vYYYYMMDD-deadbeef"
    echo

    exit 1
  fi

  VERSION=${1}

  if [ "${VERSION}" = "istio" ] || [ "${VERSION}" = "upstream" ]; then
    VERSION=$(get_remote_version "${VERSION}")
    echo "Resolved special value ${1} to version ${VERSION}"
  fi
}

function get_remote_version() {
  local url

  case ${1} in
    istio) url="https://raw.githubusercontent.com/istio/test-infra/master/prow/cluster/deck_deployment.yaml";;
    upstream) url="https://raw.githubusercontent.com/kubernetes/test-infra/master/config/prow/cluster/deck_deployment.yaml";;
    *) echo "invalid value for get_remote_version()" && exit 1
  esac

  curl -sLf "${url}" | grep image: | grep -o -E 'v[-0-9a-f]+'
}


function run_sed() {
  local filter="s|gcr.io/k8s-prow/\([[:alnum:]_-]\+\):v[a-f0-9-]\+|gcr.io/k8s-prow/\1:${VERSION}|I"

  echo "Updating files"
  find . -name '*.yaml' -print0 | xargs -0 -r sed -i "${filter}"
}

function run_make_gen() {
  echo "Running make gen..."
  cd "${ROOTDIR}"
  make gen
}

function main() {
  validate_args "$@"
  run_sed
  run_make_gen

  echo
  echo "Done. You can now inspect the files and create a PR"
  echo
}

main "$@"
