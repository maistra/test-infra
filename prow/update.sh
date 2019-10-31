#!/bin/bash

set -ex

# update config and plugins
oc create configmap config --from-file=config.yaml=config.yaml --dry-run -o yaml | kubectl replace configmap -n default config -f -
oc create configmap plugins --from-file=plugins.yaml=plugins.yaml --dry-run -o yaml | kubectl replace configmap -n default plugins -f -

# update deployments etc.
for file in `ls cluster`; do
  kubectl apply -f cluster/$file
done
