#!/bin/sh
set -ex

export GOBIN=/usr/local/bin

mkdir $HOME/src
cd $HOME/src
git clone https://github.com/gohugoio/hugo.git
cd hugo
go install --tags extended

dnf install -y ruby ruby-devel
gem install --no-user-install asciidoctor
gem install --no-user-install html-proofer
gem install --no-user-install mdspell

