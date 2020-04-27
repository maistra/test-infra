#!/bin/bash

#FIXME: Remove this file once we drop 1.0 Dockerfile

set -ex

## Install base dependencies

dnf install -y xz unzip hostname \
               make automake gcc gcc-c++ git diffutils \
               which
