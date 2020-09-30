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
SHA="$(git rev-parse --short=8 HEAD)"

function validate_args() {
  if [ $# -ne 1 ] || [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
    echo "Updates maistra-builder image references"
    echo
    echo "Usage: ${0} <sha>"
    echo

    exit 1
  fi

  SHA=${1}
}

function run_sed() {
  echo "Updating versions with SHA ${SHA}"
  sed -i -e "s|^\(BUILDER_IMAGE_1_0\)=\".*\"$|\1=\"1.0-${SHA}\"|" prow/gen-config.sh
  sed -i -e "s|^\(BUILDER_IMAGE_1_1\)=\".*\"$|\1=\"1.1-${SHA}\"|" prow/gen-config.sh
  sed -i -e "s|^\(BUILDER_IMAGE_2_0\)=\".*\"$|\1=\"2.0-${SHA}\"|" prow/gen-config.sh
  sed -i -e "s|^\(PROXY_BUILDER_IMAGE_1_1\)=\".*\"$|\1=\"1.1-${SHA}\"|" prow/gen-config.sh
  sed -i -e "s|^\(PROXY_BUILDER_IMAGE_2_0\)=\".*\"$|\1=\"2.0-${SHA}\"|" prow/gen-config.sh
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
