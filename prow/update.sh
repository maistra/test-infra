#!/bin/bash

set -ex

# safety measure: make sure we're on the right cluster
(kubectl get nodes | grep prow-worker-01) || (echo "Wrong cluster. Exiting..."; exit 1)

# make sure we use the latest configuration
sh gen-config.sh

# update config and plugins
kubectl create configmap config --from-file=config.yaml=config.gen.yaml --dry-run -o yaml | kubectl replace configmap -n default config -f -
kubectl create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl replace configmap -n default plugins -f -

# update deployments etc.
for file in `ls cluster`; do
  kubectl apply -f cluster/$file
done

# restart deployments
for deployment in `kubectl get deployments -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'`; do
  kubectl rollout restart deployment $deployment
done
