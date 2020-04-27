#!/bin/bash

#FIXME: Remove this file once support for 1.0 is removed

set -ex

## Install shellcheck

export SHELLCHECK_VERSION=v0.7.0

curl https://storage.googleapis.com/shellcheck/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJ -C /tmp

mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck /usr/local/bin/shellcheck
