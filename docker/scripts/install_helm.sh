#!/bin/bash

#FIXME: Remove this file once support for 1.0 is removed

set -ex

## Install helm

curl https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1
mv helm /usr/local/bin
