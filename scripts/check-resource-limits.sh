#!/bin/bash

set -eu

ret=0;

echo "Checking jobs for resource limits and requests"

# Looks for yq-go (https://github.com/mikefarah/yq) first, as installed in CI image, fallbacks to yq.
# Note there's another yq package, written in python, which is not the one we want: https://github.com/kislyuk/yq
# https://issues.redhat.com/browse/MAISTRA-1717
# shellcheck disable=SC2230
YQ=$(which yq-go 2>/dev/null || which yq 2>/dev/null || echo "")

if ! [ -x "$(command -v "${YQ}")" ]; then
  echo "Please install the golang yq package"
  exit 1
else
  s="yq .* version 4.*"
  if ! [[ $(${YQ} --version) =~ $s ]]; then
    echo "Install the correct (golang) yq package"
    exit 1
  fi
fi

for jobtype in presubmit postsubmit; do
    while read -r job; do
        read -ra jobArray <<< "${job}"
        name=${jobArray[0]}
        resources=${jobArray[1]}
        if [ "${resources}" = "null" ]; then
            ret=1
            echo "Error: the ${jobtype} job ${name} does not define" \
                 "resource requests and limits. Please add them!"
        fi;
    done <<< "$(${YQ} -o json -P prow/config.gen.yaml | jq -r ".${jobtype}s[]|.[]|  .name + \" \" + (.spec.containers[0].resources|tostring)")";
done

exit ${ret}
