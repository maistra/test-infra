FROM centos:8

# Versions
ENV K8S_TEST_INFRA_VERSION=41512c7491a99c6bdf330e1a76d45c8a10d3679b
ENV GCLOUD_VERSION=312.0.0

RUN dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y config-manager --set-enabled PowerTools && \
    dnf -y install git make libtool patch libatomic which \
                   autoconf automake libtool cmake python2 python3 \
                   gcc gcc-c++ ninja-build golang annobin libstdc++-static \
                   java-11-openjdk-devel jq file diffutils && \
    dnf -y clean all

# Bazel
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/2.2.0/bazel-2.2.0-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin k8s.io/test-infra/robots/pr-creator@${K8S_TEST_INFRA_VERSION}

ENV CC=gcc CXX=g++ USER=user HOME=/home/user
RUN mkdir -p /home/user && chmod 777 /home/user

WORKDIR /work

RUN ln -s /usr/bin/python3 /usr/bin/python

# Google cloud tools
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz
ENV PATH=/usr/local/google-cloud-sdk/bin:$PATH
