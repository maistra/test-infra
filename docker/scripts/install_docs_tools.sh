#!/bin/sh
set -ex

HUGO_VERSION=0.46

curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
 --OUTPUT /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
tar -xzvf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp
mv /tmp/hugo /usr/local/bin

#install vale which will provide us spell checking and eventually linting
curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o vale.sh
chmod +x vale.sh
./vale.sh -b /usr/local/bin v2.1.0

#install yq for use in yaml parsing
GO111MODULE=on go get github.com/mikefarah/yq/v3

# Ruby tools
dnf -y install rubygems ruby-devel zlib-devel redhat-rpm-config

gem install --no-wrappers --no-document html-proofer -v 3.15.3
gem install --no-wrappers --no-document asciidoctor -v 2.0.10
