#!/bin/bash

set -ex

## Install base dependencies

dnf install -y xz unzip hostname \
               make automake gcc gcc-c++ git diffutils \
               which jq python3-pip

#install yqv2 for istio-operator
pip3 install yq
