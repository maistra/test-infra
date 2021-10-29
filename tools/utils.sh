#!/usr/bin/env bash
# shellcheck disable=SC2120

# Copyright Istio Authors
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

set -euo pipefail
shopt -s globstar dotglob extglob

export BASHOPTS

print_error() {
  local last_return="$?"

  {
    echo
    echo "${1:-unknown error}"
    echo
  } >&2

  return "${2:-$last_return}"
}

print_error_and_exit() {
  print_error "${1:-unknown error}"
  exit "${2:-1}"
}

split_on_commas() {
  local array
  IFS=, read -r -a array <<<"$1"
  echo "${array[@]}"
}

evaluate_tmpl() {
  bash -c "eval echo \"$1\""
}

current_branch() {
  git symbolic-ref --quiet --short "$@" HEAD
}

current_tag() {
  git describe --tags --exact-match "$@"
}

current_sha() {
  git rev-parse "$@" HEAD
}

commit_date() {
   git show -s --date=short --pretty='format:%ad' "$(current_sha)"
}

current_ref() {
  current_branch || current_tag || current_sha
}

hash() {
  local val="$1"
  echo -n "$val" | md5sum | cut -c1-8
}

trace() {
  set -x
  "$@"
}
