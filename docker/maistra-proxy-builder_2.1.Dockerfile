# Hack: Remove this once the base image has go 1.16
FROM golang:1.16.4 AS go116

ENV K8S_TEST_INFRA_VERSION=03cf33ddeb
RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
    cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
    go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
    go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go

FROM centos:8

# In order to use gcc 9 in this image, make sure to run:
#   source scl_source enable gcc-toolset-9

# Versions
ENV K8S_TEST_INFRA_VERSION=03cf33ddeb
ENV GCLOUD_VERSION=312.0.0

RUN dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf -y config-manager --set-enabled powertools && \
    dnf -y install git make libtool patch which ninja-build golang \
                   autoconf automake libtool cmake python2 python3 nodejs \
                   gcc-toolset-9 gcc-toolset-9-libatomic-devel annobin-annocheck \
                   java-11-openjdk-devel jq file diffutils lbzip2 && \
    dnf -y clean all

# Add tools to compile WASM extensions, temporarily using COPR until we have them packaged for centos:8
RUN dnf -y copr enable jwendell/clang11 && \
    dnf -y copr enable jwendell/llvm11 && \
    dnf -y copr enable jwendell/lld11 && \
    dnf -y copr enable jwendell/binaryen && \
    dnf -y upgrade --refresh && \
    dnf -y install clang-11.0.0-2.el8 clang-tools-extra-11.0.0-2.el8 clang-analyzer-11.0.0-2.el8 \
                   llvm-11.0.0-3.el8 llvm-devel-11.0.0-3.el8 \
                   lld-11.0.0-4.el8 \
                   binaryen-90-1.el8 && \
    dnf -y clean all

# Bazel
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/3.4.1/bazel-3.4.1-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Go tools
# Hack: Revert this once the base image has go 1.16
# RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
#     cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
#     go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
#     go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go && \
#     rm -rf /root/* /root/.cache /tmp/*
COPY --from=go116 /usr/local/bin/pr-creator /usr/local/bin/pr-creator
COPY --from=go116 /usr/local/bin/checkconfig /usr/local/bin/checkconfig

ENV CC=gcc CXX=g++ USER=user HOME=/home/user
RUN useradd user && chmod 777 /home/user

WORKDIR /work

RUN ln -s /usr/bin/python3 /usr/bin/python

# Google cloud tools
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz
ENV PATH=/usr/local/google-cloud-sdk/bin:$PATH
