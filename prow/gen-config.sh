#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NAMESPACE=${NAMESPACE:-default}
WORKER_NS=${WORKER_NS:-test-pods}

# re-generate config
echo "#======================================
# This configuration is auto-generated. 
# To update:
#    Modify files in the config directory
#    Run gen-config.sh to regenerate.
#======================================" > config.gen.yaml

for file in ${DIR}/config/*; do
  sed -e 's@${NAMESPACE}@'"${NAMESPACE}"'@' -e 's@${WORKER_NS}@'"${WORKER_NS}"'@' "${file}" >> ${DIR}/config.gen.yaml
done
