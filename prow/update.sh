#!/bin/bash

set -ex

# safety measure: make sure we're on the right cluster
(kubectl get nodes | grep prow-worker-01) || (echo "Wrong cluster. Exiting..."; exit 1)

# make sure we use the latest configuration
sh gen-config.sh

# update config and plugins
kubectl -n default create configmap config --from-file=config.yaml=config.gen.yaml --dry-run -o yaml | kubectl -n default replace configmap config -f -
kubectl -n default create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl -n default replace configmap plugins -f -

# update deployments etc.
for file in cluster/*; do
  kubectl apply -f "${file}"
done

# restart deployments
for deployment in $(kubectl get deployments -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  kubectl -n default rollout restart deployment "${deployment}"
done
