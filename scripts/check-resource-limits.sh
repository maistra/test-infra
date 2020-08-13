#!/bin/bash

set -eu

ret=0;

echo "Checking jobs for resource limits and requests"

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
    done <<< "$(yq r -Pj prow/config.gen.yaml | jq -r ".${jobtype}s[]|.[]|  .name + \" \" + (.spec.containers[0].resources|tostring)")";
done

exit ${ret}
