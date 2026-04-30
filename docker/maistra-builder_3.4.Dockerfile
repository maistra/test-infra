FROM quay.io/fedora/fedora:43

ENV GOLANG_VERSION=1.25.9
ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO111MODULE=on
ENV GOSUMDB=sum.golang.org
ENV GOCACHE=/gocache
ENV GOBIN=/usr/local/bin

WORKDIR /root

# Install all dependencies available in RPM repos
# hadolint ignore=DL3008, DL3009
RUN dnf -y install --setopt=install_weak_deps=False --allowerasing dnf-plugins-core && \
    dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo && \
    dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf -y install --setopt=install_weak_deps=False --allowerasing \
        gh \
        util-linux-script \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
        ca-certificates curl gnupg2 \
        openssh libtool libtool-ltdl glibc glibc-devel glibc-static \
        gcc gcc-c++ binutils \
        make pkgconf-pkg-config binutils-gold \
        python3.12 python3.12-devel python3-pip python3-setuptools \
        wget jq rsync \
        perl-IPC-Cmd perl-FindBin \
        clang18-devel llvm18-devel lld18 libatomic libstdc++-static \
        libcxx-devel libcxxabi-devel libcxx-static libcxxabi-static \
        libcurl-devel \
        git less rpm rpm-build gettext file \
        iproute ipset rsync net-tools \
        ninja-build \
        sudo autoconf automake cmake unzip wget xz procps \
        libbpf-devel \
        java-21-openjdk-devel \
        ruby ruby-devel rubygem-json \
        cargo rust protobuf-compiler \
        openssl-3.5* openssl-devel-3.5* \
        ncurses-compat-libs && \
    dnf clean all -y

# Configure LLVM/CLang 18 links
RUN ln -s /usr/bin/clang-18 /usr/bin/clang && \
    ln -s /usr/bin/clang++-18 /usr/bin/clang++ && \
    ln -s /usr/bin/llvm-ar-18 /usr/bin/llvm-ar && \
    ln -s /usr/bin/llvm-nm-18 /usr/bin/llvm-nm && \
    ln -s /usr/bin/llvm-ranlib-18 /usr/bin/llvm-ranlib && \
    ln -s /usr/bin/llvm-strip-18 /usr/bin/llvm-strip && \
    ln -s /usr/bin/lld-18 /usr/bin/lld && \
    ln -s /usr/bin/lld-18 /usr/bin/ld.lld && \
    ln -s /usr/bin/lld-link-18 /usr/bin/lld-link

# Create symlinks for Ubuntu/Debian paths (needed by vendored LLVM toolchain)
# The vendored toolchain expects Ubuntu-style library paths
RUN mkdir -p /lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu && \
    # Verify ncurses-compat-libs provides real libtinfo.so.5
    ls -la /usr/lib64/libtinfo.so.5* && \
    # Link standard C library and dynamic linker
    ln -sf /lib64/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6 && \
    ln -sf /lib64/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 && \
    ln -sf /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 && \
    # Link ncurses library from compat package (provides real libtinfo.so.5.9)
    ln -sf /usr/lib64/libtinfo.so.5 /lib/x86_64-linux-gnu/libtinfo.so.5 && \
    ln -sf /usr/lib64/libtinfo.so.5 /lib64/libtinfo.so.5 && \
    # Link glibc CRT files (crt1.o, crti.o, crtn.o) - these contain __libc_csu_init/__libc_csu_fini
    ln -sf /usr/lib64/crt1.o /usr/lib/x86_64-linux-gnu/crt1.o && \
    ln -sf /usr/lib64/crti.o /usr/lib/x86_64-linux-gnu/crti.o && \
    ln -sf /usr/lib64/crtn.o /usr/lib/x86_64-linux-gnu/crtn.o && \
    ln -sf /usr/lib64/gcrt1.o /usr/lib/x86_64-linux-gnu/gcrt1.o 2>/dev/null || true && \
    ln -sf /usr/lib64/Scrt1.o /usr/lib/x86_64-linux-gnu/Scrt1.o 2>/dev/null || true && \
    # Link GCC CRT files (crtbegin*.o, crtend*.o)
    for f in /usr/lib/gcc/x86_64-redhat-linux/*/crt*.o; do \
        [ -f "$f" ] && ln -sf "$f" /usr/lib/x86_64-linux-gnu/$(basename "$f"); \
    done && \
    # Link libc static archives
    ln -sf /usr/lib64/libc.a /usr/lib/x86_64-linux-gnu/libc.a 2>/dev/null || true && \
    ln -sf /usr/lib64/libc_nonshared.a /usr/lib/x86_64-linux-gnu/libc_nonshared.a 2>/dev/null || true && \
    # Link additional system libraries
    ln -sf /lib64/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6 && \
    ln -sf /lib64/libm.so.6 /usr/lib/x86_64-linux-gnu/libm.so.6 && \
    ln -sf /lib64/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0 && \
    ln -sf /lib64/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2 && \
    ln -sf /lib64/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1 && \
    ln -sf /lib64/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1 && \
    ln -sf /lib64/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6

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
# go-junit-report is used by Istio unit tests
ENV K8S_TEST_INFRA_VERSION=1f0e63447a32a07c0a6cc1ae3b95172438b373c8
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" k8s.io/test-infra/robots/pr-creator@${K8S_TEST_INFRA_VERSION}
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" golang.org/x/tools/cmd/goimports@v0.28.0
RUN CGO_ENABLED=0 go install -ldflags="-extldflags -static -s -w" github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION}

# Google cloud tools
ENV GCLOUD_VERSION=496.0.0
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
ENV BAZEL_VERSION=7.7.1
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
