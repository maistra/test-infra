FROM quay.io/fedora/fedora:41

ENV GOLANG_VERSION=1.24.5
ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO111MODULE=on
ENV GOSUMDB=sum.golang.org
ENV GOCACHE=/gocache
ENV GOBIN=/usr/local/bin

WORKDIR /root

ENV DOCKER_VERSION=3:28.0.4
ENV DOCKER_CLI_VERSION=1:28.0.4
ENV CONTAINERD_VERSION=1.7.26
ENV DOCKER_BUILDX_VERSION=0.22.0
ENV K8S_TEST_INFRA_VERSION=1f0e63447a32a07c0a6cc1ae3b95172438b373c8

# Install rust 1.85 needed by ztunnel
ARG RUST_VERSION=1.85.1
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain ${RUST_VERSION} && \
    mv /root/.rustup/toolchains/${RUST_VERSION}-*-unknown-linux-gnu/bin/* /usr/bin/

# Install all dependencies available in RPM repos
# hadolint ignore=DL3008, DL3009
RUN dnf -y install --setopt=install_weak_deps=False --allowerasing dnf-plugins-core && \
    dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo && \
    dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf -y install --setopt=install_weak_deps=False --allowerasing \
        gh \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        ca-certificates curl gnupg2 \
        openssh libtool libtool-ltdl glibc \
        make pkgconf-pkg-config \
        python3.12 python3.12-devel python3-pip python3-setuptools \
        wget jq rsync \
        perl-IPC-Cmd perl-FindBin \
        clang18-devel llvm18-devel lld18 libatomic libstdc++-static \
        libcurl-devel \
        git less rpm rpm-build gettext file \
        iproute ipset rsync net-tools \
        ninja-build \
        sudo autoconf automake cmake unzip wget xz procps \
        libbpf-devel \
        java-11-openjdk-devel \
        ruby ruby-devel rubygem-json && \
    dnf clean all -y

# Configure LLVM/CLang 18 links
RUN ln -s /usr/bin/clang-18 /usr/bin/clang && \
    ln -s /usr/bin/clang++-18 /usr/bin/clang++ && \
    ln -s /usr/bin/llvm-ar-18 /usr/bin/llvm-ar && \
    ln -s /usr/bin/llvm-nm-18 /usr/bin/llvm-nm && \
    ln -s /usr/bin/llvm-ranlib-18 /usr/bin/llvm-ranlib && \
    ln -s /usr/bin/llvm-strip-18 /usr/bin/llvm-strip && \
    ln -s /usr/bin/lld-18 /usr/bin/lld && \
    ln -s /usr/bin/lld-link-18 /usr/bin/lld-link

# Install golang from go.dev/dl
# hadolint ignore=DL3008
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) GOLANG_GZ=go${GOLANG_VERSION}.linux-amd64.tar.gz;; \
        aarch64) GOLANG_GZ=go${GOLANG_VERSION}.linux-arm64.tar.gz;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -nv -O "/tmp/${GOLANG_GZ}" "https://go.dev/dl/${GOLANG_GZ}" && \
    tar -xzf "/tmp/${GOLANG_GZ}" -C /tmp && \
    mv /tmp/go /usr/lib/golang && \
    ln -s /usr/lib/golang/bin/go /usr/local/bin/go && \
    rm -rf "/tmp/${GOLANG_GZ}" /usr/lib/golang/doc /usr/lib/golang/test /usr/lib/golang/api /usr/lib/golang/bin/godoc /usr/lib/golang/bin/gofmt

# Go tools
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" k8s.io/test-infra/robots/pr-creator@${K8S_TEST_INFRA_VERSION}

# OpenSSL 3.0.x
ENV OPENSSL_VERSION=3.0.17
ENV OPENSSL_ROOT_DIR=/opt/openssl
RUN curl -sfL https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz | tar xz -C /tmp && \
    cd /tmp/openssl-${OPENSSL_VERSION} && \
    ./Configure --prefix=${OPENSSL_ROOT_DIR} --openssldir=${OPENSSL_ROOT_DIR}/conf && \
    make -j build_sw && make install_sw && \
    cd /tmp && rm -rf /tmp/openssl-${OPENSSL_VERSION}

# Google cloud tools
ENV GCLOUD_VERSION=496.0.0
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz

# Bazel
ENV BAZEL_VERSION=7.6.0
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Install su-exec which is a tool that operates like sudo without the overhead
ENV SU_EXEC_VERSION=0.3.1
RUN wget -nv https://github.com/NobodyXu/su-exec/archive/refs/tags/v${SU_EXEC_VERSION}.tar.gz && \
    tar zxf v${SU_EXEC_VERSION}.tar.gz && \
    cd su-exec-${SU_EXEC_VERSION} && \
    make LDFLAGS="-fvisibility=hidden -Wl,-O2 -Wl,--discard-all -Wl,--strip-all -Wl,--as-needed -Wl,--gc-sections" && \
    cp -a su-exec /usr/bin && chmod u+sx /usr/bin/su-exec && \
    cd .. && rm -rf su-exec-${SU_EXEC_VERSION} v${SU_EXEC_VERSION}.tar.gz

# Workarounds for proxy and bazel
RUN useradd user && chmod 777 /home/user
ENV USER=user HOME=/home/user
RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# mountpoints are mandatory for any host mounts.
# mountpoints in /config are special.
RUN mkdir -p /go && \
    mkdir -p /gocache && \
    mkdir -p /gobin && \
    mkdir -p /config/.docker && \
    mkdir -p /config/.config/gcloud && \
    mkdir -p /config/.kube && \
    mkdir -p /config-copy && \
    mkdir -p /home/.cache && \
    mkdir -p /home/.helm && \
    mkdir -p /home/.gsutil

# TODO must sort out how to use uid mapping in docker so these don't need to be 777
# They are created as root 755.  As a result they are not writeable, which fails in
# the developer environment as a volume or bind mount inherits the permissions of
# the directory mounted rather then overridding with the permission of the volume file.
RUN chmod -R 777 /go && \
    chmod -R 777 /gocache && \
    chmod 777 /gobin && \
    chmod 777 /config && \
    chmod 777 /config/.docker && \
    chmod 777 /config/.config/gcloud && \
    chmod 777 /config/.kube && \
    chmod 777 /home/.cache && \
    chmod 777 /home/.helm && \
    chmod 777 /home/.gsutil

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work

ENV PATH=/usr/lib/llvm/bin:/usr/local/google-cloud-sdk/bin:$PATH

ADD scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Run config setup in local environments
COPY scripts/docker-entrypoint-3.0.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
