FROM centos:8

# Versions
ENV K8S_TEST_INFRA_VERSION=41512c7491a99c6bdf330e1a76d45c8a10d3679b

RUN curl -o /etc/yum.repos.d/bazel.repo -Ls https://copr.fedorainfracloud.org/coprs/g/maistra/bazel.el8-1.2/repo/epel-8/group_maistra-bazel.el8-1.2-epel-8.repo

RUN dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y config-manager --set-enabled PowerTools && \
    dnf -y install git make libtool patch libatomic which \
                   autoconf automake libtool cmake python3 \
                   gcc gcc-c++ ninja-build golang annobin \
                   java-11-openjdk-devel bazel jq && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin k8s.io/test-infra/robots/pr-creator@${K8S_TEST_INFRA_VERSION}

ENV CC=gcc CXX=g++ USER=user HOME=/home/user
RUN mkdir -p /home/user && chmod 777 /home/user

WORKDIR /work

RUN ln -s /usr/bin/python3 /usr/bin/python
