#!/bin/bash

set -ex

NAMESPACE=${NAMESPACE:-default}
WORKER_NS=${WORKER_NS:-test-pods}

# create test-pods namespace
kubectl create namespace "${WORKER_NS}" || echo Skipping

# create configmaps
kubectl -n "${NAMESPACE}" create cm config || echo Skipping
kubectl -n "${NAMESPACE}" create cm plugins || echo Skipping

# create secrets
kubectl -n "${NAMESPACE}" create secret generic hmac-token --from-file=hmac=secrets/github-hmac-secret || echo Skipping
kubectl -n "${NAMESPACE}" create secret generic cookie --from-file=secret=secrets/cookie-secret || echo Skipping
kubectl -n "${NAMESPACE}" create secret generic oauth-token --from-file=oauth=secrets/github-token || echo Skipping
kubectl -n "${NAMESPACE}" create secret generic gcs-credentials --from-file=service-account.json=secrets/gcs-credentials.json || echo Skipping

kubectl -n "${WORKER_NS}" create secret generic github-token --from-file=github-token=secrets/github-token || echo Skipping
kubectl -n "${WORKER_NS}" create secret generic gcs-credentials --from-file=service-account.json=secrets/gcs-credentials.json || echo Skipping
kubectl -n "${WORKER_NS}" create secret generic quay-pusher-dockercfg --from-file=config.json=secrets/maistra-dev-prow-auth.json || echo Skipping
kubectl -n "${WORKER_NS}" create secret generic copr --from-file=copr=secrets/copr-token-bot || echo Skipping

# create service account including secret holding kubeconfig (for auto-updating prow config on merged PRs)
./setup-prow-deployer.sh

# install nginx-ingress
kubectl create namespace ingress || echo Skipping
helm template --name ingress --namespace ingress \
  --set rbac.create=true \
  --set controller.kind=DaemonSet \
  --set controller.service.type=ClusterIP,controller.hostNetwork=true \
  --set controller.resources.requests.cpu=100m, \
  --set controller.resources.requests.memory=64Mi \
  --set controller.resources.limits.cpu=500m \
  --set controller.resources.limits.memory=512Mi \
  nginx-ingress | kubectl apply -n ingress -f -

# install cert-manager
kubectl create namespace cert-manager || echo Skipping
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
sleep 10

# deploy prow
./update.sh
