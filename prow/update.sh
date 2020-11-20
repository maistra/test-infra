#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NAMESPACE=${NAMESPACE:-default}
WORKER_NS=${WORKER_NS:-test-pods}

# safety measure: make sure we're on the right cluster
(kubectl get nodes | grep prow-worker-01) || (echo "Wrong cluster. Exiting..."; exit 1)

# make sure we use the latest configuration
sh gen-config.sh

# update config and plugins
kubectl -n "${NAMESPACE}" create configmap config --from-file=config.yaml=config.gen.yaml --dry-run -o yaml | kubectl -n default replace configmap config -f -
kubectl -n "${NAMESPACE}" create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl -n default replace configmap plugins -f -

# update deployments etc.
for file in ${DIR}/cluster/*; do
  sed -e 's@${NAMESPACE}@'"${NAMESPACE}"'@' 's@${WORKER_NS}@'"${WORKER_NS}"'@' $file | kubectl apply -f -
done

# restart deployments
for deployment in $(kubectl get deployments -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  kubectl -n "${NAMESPACE}" rollout restart deployment "${deployment}"
done
