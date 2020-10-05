#!/bin/bash

set -ex

## Install shellcheck

export SHELLCHECK_VERSION=v0.7.0

curl -L https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJv -C /tmp

mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck /usr/local/bin/shellcheck
