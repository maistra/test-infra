#!/bin/bash


export GOPATH="`pwd`/"
export GOBIN="$GOPATH/bin"
export GOROOT=/usr/lib/golang/
export PATH="$PATH:$GOPATH/bin"

mkdir -p $GOPATH/src/github.com/$REPO_OWNER/
cd $GOPATH/src/github.com/$REPO_OWNER/
git clone https://github.com/$REPO_OWNER/$REPO_NAME.git 
cd $REPO_NAME
git checkout $PULL_PULL_SHA

oc login $QE_CLUSTER_ADDRESS -u $QE_IKE_CLUSTER_USER -p $QE_IKE_CLUSTER_PWD --insecure-skip-tls-verify=true
     IKE_CLUSTER_USER=$QE_IKE_CLUSTER_USER \
     IKE_CLUSTER_PWD=$QE_IKE_CLUSTER_PWD \
     IKE_CLUSTER_HOST=$QE_IKE_CLUSTER_HOST \
     ISTIO_NS=$QE_ISTIO_NS \
     IKE_CLUSTER_ADDRESS=$QE_CLUSTER_ADDRESS \
make deps tools test-e2e