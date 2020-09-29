#!/bin/bash

set -ex

DOCKER_VERSION="19.03*"

yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# we have to manually install containerd.io to resolve a conflict
yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.2-3.3.el7.x86_64.rpm

yum install -y "docker-ce-${DOCKER_VERSION}" "docker-ce-cli-${DOCKER_VERSION}"
