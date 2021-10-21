FROM quay.io/centos/centos:stream8

# In order to use gcc 9 in this image, make sure to run:
#   source /opt/rh/gcc-toolset-9/enable

# In order to use gcc 11 in this image, make sure to run:
#   source /opt/rh/gcc-toolset-11/enable

# Versions
ENV K8S_TEST_INFRA_VERSION=5763223177
ENV GCLOUD_VERSION=360.0.0
ENV BAZEL_VERSION=4.2.1

RUN dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  && \
    dnf -y config-manager --set-enabled powertools && \
    dnf -y copr enable jwendell/binaryen && \
    dnf -y install git make libtool patch which ninja-build golang xz \
                   autoconf automake libtool cmake python2 python3 nodejs \
                   gcc-toolset-9 gcc-toolset-9-libatomic-devel gcc-toolset-9-annobin \
                   gcc-toolset-11 gcc-toolset-11-libatomic-devel gcc-toolset-11-annobin-plugin-gcc \
                   java-11-openjdk-devel jq file diffutils lbzip2 annobin-annocheck \
                   clang llvm lld \
                   binaryen && \
    dnf -y clean all

# Bazel
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Go tools
RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
    cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
    go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
    go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go && \
    rm -rf /root/* /root/.cache /tmp/*

ENV CC=gcc CXX=g++ USER=user HOME=/home/user
RUN useradd user && chmod 777 /home/user

WORKDIR /work

RUN ln -s /usr/bin/python3 /usr/bin/python

# Google cloud tools
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz
ENV PATH=/usr/local/google-cloud-sdk/bin:$PATH
