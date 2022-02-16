#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NAMESPACE=${NAMESPACE:-default}
WORKER_NS=${WORKER_NS:-test-pods}

GEN_CONFIG_FILE="${DIR}/config.gen.yaml"
# re-generate config
echo "#======================================
# This configuration is auto-generated. 
# To update:
#    Modify files in the config directory
#    Run gen-config.sh to regenerate.
#======================================" > "${GEN_CONFIG_FILE}"

for file in "${DIR}"/config/*; do
  # shellcheck disable=SC2016 ## in case of sed expression first '' is not an actual variable to be expanded
  sed -e 's@${NAMESPACE}@'"${NAMESPACE}"'@g' -e 's@${WORKER_NS}@'"${WORKER_NS}"'@g' "${file}" >> "${GEN_CONFIG_FILE}"
  printf '\n' >> "${GEN_CONFIG_FILE}"
done
