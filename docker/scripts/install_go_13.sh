#!/bin/bash

set -ex

## Install golang 1.13.6 && some libs

curl https://dl.google.com/go/go1.13.6.linux-amd64.tar.gz | tar -xz -C /usr/local

go version

export GOPATH=/root/go

go get github.com/jstemmer/go-junit-report
