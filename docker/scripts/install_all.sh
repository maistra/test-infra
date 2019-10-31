#!/bin/bash

set -ex

## Install base dependencies

dnf install -y xz hostname \
               make automake gcc gcc-c++ git diffutils

## Install golang 1.12.12 && some libs

curl https://dl.google.com/go/go1.12.12.linux-amd64.tar.gz | tar -xz -C /usr/local

go version

go get github.com/github/hub
go get github.com/golang/dep/cmd/dep
go get -u google.golang.org/api/sheets/v4
go get github.com/jstemmer/go-junit-report

## Install shellcheck

export SHELLCHECK_VERSION=v0.7.0

curl https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJ -C /tmp

mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck /usr/local/bin/shellcheck
