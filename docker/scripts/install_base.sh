#!/bin/bash

set -ex

## Install base dependencies

dnf install -y xz unzip hostname \
               make automake gcc gcc-c++ git diffutils \
               which
