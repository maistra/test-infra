#!/bin/bash

set -ex

# update config and plugins
kubectl create configmap config --from-file=config.yaml=config.yaml --dry-run -o yaml | kubectl replace configmap -n default config -f -
kubectl create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl replace configmap -n default plugins -f -

# update deployments etc.
for file in `ls cluster`; do
  kubectl apply -f cluster/$file
done

# restart deployments
for deployment in `kubectl get deployments -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'`; do
  kubectl rollout restart deployment $deployment
done
