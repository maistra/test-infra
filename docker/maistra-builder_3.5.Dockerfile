FROM registry.access.redhat.com/ubi9/ubi:9.8

ENV GOLANG_VERSION=1.26.4
ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO111MODULE=on
ENV GOSUMDB=sum.golang.org
ENV GOCACHE=/gocache
ENV GOBIN=/usr/local/bin

WORKDIR /root

# Install all dependencies available in RPM repos
# hadolint ignore=DL3008, DL3009
RUN dnf -y install --setopt=install_weak_deps=False --allowerasing dnf-plugins-core && \
    dnf config-manager addrepo --add-repo https://cli.github.com/packages/rpm/gh-cli.repo && \
    dnf config-manager addrepo --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
    dnf -y install --setopt=install_weak_deps=False --allowerasing \
        gh \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        ca-certificates curl gnupg2 \
        openssh libtool libtool-ltdl glibc glibc-devel glibc-static \
        gcc gcc-c++ binutils \
        make pkgconf-pkg-config binutils-gold \
        python3.12 python3.12-devel python3-pip python3-setuptools \
        wget jq rsync \
        perl-IPC-Cmd perl-FindBin \
        clang-devel llvm-devel lld clang-tools-extra libatomic libstdc++-static \
        gcc-toolset-15-libstdc++-devel gcc-toolset-15-libatomic-devel \
        libcurl-devel \
        git less rpm rpm-build gettext file \
        iproute ipset rsync net-tools \
        ninja-build \
        sudo autoconf automake cmake unzip wget xz procps \
        java-25-openjdk-devel \
        ruby ruby-devel rubygem-json \
        openssl-3.5* openssl-devel-3.5* && \
    dnf clean all -y

# link gcc toolset 15 to standard path so bazel can find it
RUN ln -s /opt/rh/gcc-toolset-15/root/usr/include/c++/15 /usr/include/c++/15
RUN ln -s /opt/rh/gcc-toolset-15/root/usr/lib/gcc/$(uname -m)-redhat-linux/15 /usr/lib/gcc/$(uname -m)-redhat-linux/15

# Install golang from go.dev
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
# go-junit-report is used by Istio unit tests
ENV K8S_TEST_INFRA_VERSION=70b809241c9cf08ceb86a9a91ed1909e75e3378c
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV GOIMPORTS_VERSION=v0.42.0
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" k8s.io/test-infra/robots/pr-creator@${K8S_TEST_INFRA_VERSION}
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION}
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION}

# Google cloud tools
ENV GCLOUD_VERSION=558.0.0
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) PLATFORM=x86_64;; \
        aarch64) PLATFORM=arm;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-${PLATFORM}.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz

# Bazel
ENV BAZEL_VERSION=8.7.0
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) PLATFORM=x86_64;; \
        aarch64) PLATFORM=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-${PLATFORM} && \
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

# Mountpoints are mandatory for any host mounts.
# Mountpoints in /config are special.
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

# TODO: must sort out how to use uid mapping in docker so these don't need to be 777
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
