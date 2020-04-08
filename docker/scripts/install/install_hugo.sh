#!/bin/sh
set -ex

HUGO_VERSION=0.46
export GOBIN=/usr/local/bin

curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
 --OUTPUT /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
tar -xzvf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp
mv /tmp/hugo /usr/local/bin
dnf install -y ruby ruby-devel procps-ng
gem install --no-user-install asciidoctor

dnf install rubygem-nokogiri

#install vale which will provide us spell checking and eventually linting
curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh | sh -s v2.1.0 -b /usr/local/bin


