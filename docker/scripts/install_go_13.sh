#!/bin/bash

set -ex

## Install golang 1.13.6 && some libs

curl https://dl.google.com/go/go1.13.6.linux-amd64.tar.gz | tar -xz -C /usr/local

go version

export GOBIN=/usr/local/bin
go get github.com/jstemmer/go-junit-report
GO111MODULE=on go get -ldflags="-s -w" sigs.k8s.io/kind@v0.5.1
