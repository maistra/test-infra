#!/bin/bash

set -ex

# create test-pods namespace
oc new-project test-pods

# create configmaps
oc project default
oc create cm config
oc create cm plugins

# create secrets
oc create secret generic hmac-token --from-file=hmac=secrets/github-hmac-secret
oc create secret generic cookie --from-file=secret=secrets/cookie-secret
oc create secret generic oauth-token --from-file=oauth=secrets/github-token
oc create secret generic gcs-credentials -n test-pods --from-file=service-account.json=secrets/gcs-credentials.json

# install openshift-acme controller
oc new-project letsencrypt
oc create -fhttps://raw.githubusercontent.com/tnozicka/openshift-acme/master/deploy/letsencrypt-live/cluster-wide/{clusterrole,serviceaccount,imagestream,deployment}.yaml
oc adm policy add-cluster-role-to-user openshift-acme -z openshift-acme

oc project default

# deploy prow
./update.sh
