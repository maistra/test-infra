#!/bin/bash

set -ex

# create test-pods namespace
kubectl create namespace test-pods || echo Skipping

# create configmaps
kubectl create cm config || echo Skipping
kubectl create cm plugins || echo Skipping

# create secrets
kubectl create secret generic hmac-token --from-file=hmac=secrets/github-hmac-secret
kubectl create secret generic cookie --from-file=secret=secrets/cookie-secret
kubectl create secret generic oauth-token --from-file=oauth=secrets/github-token

kubectl create secret generic gcs-credentials -n test-pods --from-file=service-account.json=secrets/gcs-credentials.json
kubectl create secret generic quay-pusher-dockercfg -n test-pods --from-file=config.json=secrets/maistra-prow-auth.json

# create service account including secret holding kubeconfig (for auto-updating prow config on merged PRs)
./setup-prow-deployer.sh

# install nginx-ingress
kubectl create namespace ingress || echo Skipping
helm template --name ingress --namespace ingress \
  --set rbac.create=true,controller.kind=DaemonSet,controller.service.type=ClusterIP,controller.hostNetwork=true \
  nginx-ingress | kubectl apply -n ingress -f -

# install cert-manager
kubectl create namespace cert-manager || echo Skipping
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml

# deploy prow
./update.sh
