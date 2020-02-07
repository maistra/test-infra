#!/bin/bash

set -ex

## Install golang 1.12.15 && some libs

curl https://dl.google.com/go/go1.12.15.linux-amd64.tar.gz | tar -xz -C /usr/local

go version

export GOBIN=/usr/local/bin
go get github.com/golang/dep/cmd/dep
go get github.com/jstemmer/go-junit-report
