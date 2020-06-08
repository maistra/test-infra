#!/bin/sh
set -ex

HUGO_VERSION=0.46
export GOBIN=/usr/local/bin

curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
 --OUTPUT /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
tar -xzvf /tmp/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz -C /tmp
mv /tmp/hugo /usr/local/bin

curl https://copr.fedorainfracloud.org/coprs/bavery/asciidoctor/repo/epel-8/bavery-asciidoctor-epel-8.repo -o /etc/yum.repos.d/asciidoctor.repo
curl https://copr.fedorainfracloud.org/coprs/bavery/html-proofer/repo/epel-8/bavery-html-proofer-epel-8.repo -o /etc/yum.repos.d/html-proofer.repo
dnf install -y rubygem-asciidoctor rubygem-html-proofer

#install vale which will provide us spell checking and eventually linting
curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o vale.sh
chmod +x vale.sh
./vale.sh -b /usr/local/bin v2.1.0

#install yq for use in yaml parsing
GO111MODULE=on go get github.com/mikefarah/yq/v3
