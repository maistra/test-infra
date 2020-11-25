#!/bin/bash

set -e
#set -o xtrace

export GOPATH="`pwd`/"
export GOBIN="$GOPATH/bin"
export GOROOT=/usr/lib/golang/
export PATH="$PATH:$GOPATH/bin"

mkdir -p $GOPATH/src/github.com/$REPO_OWNER/
cd $GOPATH/src/github.com/$REPO_OWNER/
git clone https://github.com/$REPO_OWNER/$REPO_NAME.git 
cd $REPO_NAME
git checkout $PULL_PULL_SHA

oc login $IKE_CLUSTER_ADDRESS -u $IKE_CLUSTER_USER -p $IKE_CLUSTER_PWD --insecure-skip-tls-verify=true
make deps tools test-e2e