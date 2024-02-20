# Copyright Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# hadolint ignore=DL3006
FROM registry.access.redhat.com/ubi8/ubi:8.9

ARG TARGETARCH

RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac;

WORKDIR /tmp

ENV DOCKER_VERSION=20.10.24

# Stick with clang 14
# hadolint ignore=DL3008, DL3009
RUN dnf -y upgrade --refresh && \
    dnf -y module enable ruby:3.0 && \
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo && \
    dnf -y install --setopt=install_weak_deps=False --allowerasing \
    ca-certificates curl gnupg2 \
    gcc gcc-toolset-12-libatomic-devel java-11-openjdk-devel \
    openssh libtool libtool-ltdl glibc \
    make pkgconf-pkg-config \
    python3.11 python3.11-devel python3.11-pip python3.11-setuptools \
    wget jq rsync \
    openssl-devel compat-openssl10 \
    libstdc++-static \
    libcurl-devel \
    git less rpm rpm-build gettext file \
    iproute ipset rsync libbpf net-tools \
    ninja-build gh \
    sudo autoconf automake cmake unzip xz \
    ruby ruby-devel rubygem-json \
    docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_VERSION}" && \
    dnf -y clean all

# Binary tools Versions
ENV ISTIO_TOOLS_SHA=release-1.18
ENV BENCHSTAT_VERSION=9c9101da8316
ENV BOM_VERSION=v0.5.1
ENV BUF_VERSION=v1.13.1
ENV CRANE_VERSION=v0.14.0
ENV GCLOUD_VERSION=425.0.0
ENV GO_BINDATA_VERSION=v3.1.2
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV GOCOVMERGE_VERSION=b5bfa59ec0adc420475f97f89b58045c721d761c
ENV GOIMPORTS_VERSION=v0.1.0
ENV GOLANG_PROTOBUF_VERSION=v1.30.0
ENV GOLANG_GRPC_PROTOBUF_VERSION=v1.2.0
# When updating the golangci version, you may want to update the common-files config/.golangci* files as well.
ENV GOLANGCI_LINT_VERSION=v1.51.2
ENV HADOLINT_VERSION=v2.12.0
ENV HELM3_VERSION=v3.11.2
ENV HUGO_VERSION=0.111.3
ENV JB_VERSION=v0.3.1
ENV JSONNET_VERSION=v0.15.0
ENV JUNIT_MERGER_VERSION=adf1545b49509db1f83c49d1de90bbcb235642a8
ENV K8S_CODE_GENERATOR_VERSION=1.27.1
ENV K8S_TEST_INFRA_VERSION=2acdc6800510dd422bfd2a5d8c02aedc19d15f8d
ENV KIND_VERSION=v0.18.0
ENV KPT_VERSION=v0.39.3
ENV KUBECTL_VERSION=1.27.1
ENV KUBETEST2_VERSION=b019714a389563c9a788f119f801520d059b6533
ENV KUBECTX_VERSION=0.9.4
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION=v1.8.6
ENV PROTOC_GEN_SWAGGER_VERSION=v1.8.6
ENV PROTOC_GEN_VALIDATE_VERSION=v0.9.1
ENV PROTOC_VERSION=22.1
ENV PROTOLOCK_VERSION=v0.14.0
ENV PROTOTOOL_VERSION=v1.10.0
ENV SHELLCHECK_VERSION=v0.9.0
ENV SU_EXEC_VERSION=0.2
ENV TRIVY_VERSION=0.43.1
ENV YQ_VERSION=4.33.2
ENV GOLANG_VERSION=1.20.13
ENV GO111MODULE=on
ENV GOBIN=/usr/local/bin
ENV GOCACHE=/gocache
ENV GOPATH=/go
ENV GOROOT=/usr/lib/golang
ENV GOSUMDB=sum.golang.org
ENV GOPROXY="https://proxy.golang.org,direct"
ENV PATH=/usr/local/go/bin:/gobin:/usr/local/google-cloud-sdk/bin:$PATH

ENV OUTDIR=/
RUN mkdir -p ${OUTDIR}/usr/bin ${OUTDIR}/usr/local

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
    wget -q -O "/tmp/${GOLANG_GZ}" "https://go.dev/dl/${GOLANG_GZ}"; \
    tar -xzvf "/tmp/${GOLANG_GZ}" -C /tmp; \
    mv /tmp/go /usr/lib/golang; \
    ln -s /usr/lib/golang/bin/go /usr/local/bin/go; \
    rm -rf /usr/lib/golang/doc /usr/lib/golang/test /usr/lib/golang/bin/godoc

# Install protoc
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip;; \
        aarch64) PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-aarch_64.zip;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -q -O "/tmp/${PROTOC_ZIP}" "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}"; \
    unzip "/tmp/${PROTOC_ZIP}"; \
    mv /tmp/bin/protoc ${OUTDIR}/usr/bin; \
    chmod +x ${OUTDIR}/usr/bin/protoc

# Build and install a bunch of Go tools
RUN go install -ldflags="-s -w" google.golang.org/protobuf/cmd/protoc-gen-go@${GOLANG_PROTOBUF_VERSION}
RUN go install -ldflags="-s -w" google.golang.org/grpc/cmd/protoc-gen-go-grpc@${GOLANG_GRPC_PROTOBUF_VERSION}
RUN go install -ldflags="-s -w" github.com/uber/prototool/cmd/prototool@${PROTOTOOL_VERSION}
RUN go install -ldflags="-s -w" github.com/nilslice/protolock/cmd/protolock@${PROTOLOCK_VERSION}
RUN go install -ldflags="-s -w" golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION}
RUN go install -ldflags="-s -w" github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION}
RUN go install -ldflags="-s -w" github.com/go-bindata/go-bindata/go-bindata@${GO_BINDATA_VERSION}
RUN go install -ldflags="-s -w" github.com/envoyproxy/protoc-gen-validate@${PROTOC_GEN_VALIDATE_VERSION}
RUN go install -ldflags="-s -w" github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@${PROTOC_GEN_GRPC_GATEWAY_VERSION}
RUN go install -ldflags="-s -w" github.com/google/go-jsonnet/cmd/jsonnet@${JSONNET_VERSION}
RUN go install -ldflags="-s -w" github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@${JB_VERSION}
RUN go install -ldflags="-s -w" github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@${PROTOC_GEN_SWAGGER_VERSION}
RUN go install -ldflags="-s -w" github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION}
RUN go install -ldflags="-s -w" sigs.k8s.io/bom/cmd/bom@${BOM_VERSION}
RUN go install -ldflags="-s -w" sigs.k8s.io/kind@${KIND_VERSION}
RUN go install -ldflags="-s -w" github.com/wadey/gocovmerge@${GOCOVMERGE_VERSION}
RUN go install -ldflags="-s -w" github.com/imsky/junit-merger/src/junit-merger@${JUNIT_MERGER_VERSION}
RUN go install -ldflags="-s -w" golang.org/x/perf/cmd/benchstat@${BENCHSTAT_VERSION}
RUN go install -ldflags="-s -w" github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION}

# Install latest version of Istio-owned tools in this release
RUN go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-docs@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/annotations_prep@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/cue-gen@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-golang-deepcopy@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-golang-jsonshim@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/kubetype-gen@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" istio.io/tools/cmd/gen-release-notes@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/applyconfiguration-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/defaulter-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/client-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/lister-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/informer-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/deepcopy-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" k8s.io/code-generator/cmd/go-to-protobuf@kubernetes-${K8S_CODE_GENERATOR_VERSION}

# Install istio/test-infra tools
RUN go install sigs.k8s.io/kubetest2@${KUBETEST2_VERSION}
RUN go install sigs.k8s.io/kubetest2/kubetest2-gke@${KUBETEST2_VERSION}
RUN go install sigs.k8s.io/kubetest2/kubetest2-tester-exec@${KUBETEST2_VERSION}

# Go doesn't like the `replace` directives; need to do manual cloning now.
# Should be fixed by https://github.com/kubernetes/test-infra/issues/20421
# hadolint ignore=DL3003
RUN mkdir -p test-infra && \
  cd test-infra && \
  git init && \
  git remote add origin https://github.com/kubernetes/test-infra.git && \
  git fetch --depth 1 origin ${K8S_TEST_INFRA_VERSION} && \
  git checkout FETCH_HEAD && \
  go install ./robots/pr-creator && \
  go install ./prow/cmd/peribolos && \
  go install ./pkg/benchmarkjunit && \
  cd .. && rm -rf test-infra

# ShellCheck linter
RUN wget -q -O "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz"
RUN tar -xJf "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" -C /tmp
RUN mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck ${OUTDIR}/usr/bin

# Hadolint linter
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) HADOLINT_BINARY=hadolint-Linux-x86_64;; \
        aarch64) HADOLINT_BINARY=hadolint-Linux-arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -q -O ${OUTDIR}/usr/bin/hadolint https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/${HADOLINT_BINARY}; \
    chmod 555 ${OUTDIR}/usr/bin/hadolint

# Hugo static site generator
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) HUGO_TAR=hugo_${HUGO_VERSION}_Linux-64bit.tar.gz;; \
        aarch64) HUGO_TAR=hugo_${HUGO_VERSION}_Linux-ARM64.tar.gz;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -q -O /tmp/${HUGO_TAR} https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR}; \
    tar -xzvf /tmp/${HUGO_TAR} -C /tmp; \
    mv /tmp/hugo ${OUTDIR}/usr/bin

# Helm version 3
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -sfL https://get.helm.sh/helm-${HELM3_VERSION}-linux-${TARGETARCH}.tar.gz | tar -xz linux-${TARGETARCH}/helm --strip=1 && \
    mv helm /usr/local/bin/helm && chown root.root /usr/local/bin/helm && ln -s /usr/local/bin/helm /usr/local/bin/helm3

# yq doesn't support go modules, so install the binary instead
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -sfL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -o /usr/bin/yq && chmod 555 /usr/bin/yq

# Kubectl
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -sfL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl -o /usr/bin/kubectl && chmod 555 /usr/bin/kubectl

# Buf
RUN wget -q -O "${OUTDIR}/usr/bin/buf" "https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-$(uname -m)" && \
    chmod 555 "${OUTDIR}/usr/bin/buf"

# Install su-exec which is a tool that operates like sudo without the overhead
ADD https://github.com/NobodyXu/su-exec/archive/refs/tags/v${SU_EXEC_VERSION}.tar.gz /tmp
RUN tar -xzvf v${SU_EXEC_VERSION}.tar.gz
WORKDIR /tmp/su-exec-${SU_EXEC_VERSION}
RUN make
RUN cp -a su-exec ${OUTDIR}/usr/bin

# Install gcloud command line tool
# Install gcloud beta component
# Install GKE auth plugin
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) GCLOUD_TAR_FILE="google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz" ;; \
        aarch64) GCLOUD_TAR_FILE="google-cloud-sdk-${GCLOUD_VERSION}-linux-arm.tar.gz" ;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -q "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_TAR_FILE}"; \
    tar -xzvf ."/${GCLOUD_TAR_FILE}" -C "${OUTDIR}/usr/local" && rm "${GCLOUD_TAR_FILE}"; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install beta --quiet; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install alpha --quiet; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install gke-gcloud-auth-plugin --quiet; \
    rm -rf ${OUTDIR}/usr/local/google-cloud-sdk/.install/.backup \
    rm -rf ${OUTDIR}/usr/local/google-cloud-sdk/bin/anthoscli

# Trivy container scanner
RUN set -eux; \
    \
    case $(uname -m) in \
    x86_64) \
    TRVIY_DEB_NAME="trivy_${TRIVY_VERSION}_Linux-64bit.rpm"; \
    ;; \
    aarch64) \
    TRVIY_DEB_NAME="trivy_${TRIVY_VERSION}_Linux-ARM64.rpm"; \
    ;; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    wget -q -O "/tmp/${TRVIY_DEB_NAME}" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${TRVIY_DEB_NAME}"; \
    rpm -ivh "/tmp/${TRVIY_DEB_NAME}"; \
    rm "/tmp/${TRVIY_DEB_NAME}";

# Clang+LLVM versions
ENV LLVM_VERSION=14.0.6
ENV LLVM_BASE_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}
ENV LLVM_DIRECTORY=/usr/lib/llvm
ENV PATH=/usr/lib/llvm/bin:$PATH

RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) \
               LLVM_ARCHIVE=clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-rhel-8.4 \
               LLVM_ARTIFACT=clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-rhel-8.4;; \
        aarch64)  \
               LLVM_ARCHIVE=clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu \
               LLVM_ARTIFACT=clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -q ${LLVM_BASE_URL}/${LLVM_ARTIFACT}.tar.xz; \
    tar -xJf ${LLVM_ARTIFACT}.tar.xz -C /tmp; \
    mkdir -p ${LLVM_DIRECTORY}; \
    mv /tmp/${LLVM_ARCHIVE}/* ${LLVM_DIRECTORY}/

RUN echo "${LLVM_DIRECTORY}/lib" | tee /etc/ld.so.conf.d/llvm.conf
RUN ldconfig

# Bazel
ENV BAZEL_VERSION=6.3.2
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) \
               BAZEL_ARTIFACT=bazel-${BAZEL_VERSION}-linux-x86_64;; \
        aarch64)  \
               BAZEL_ARTIFACT=bazel-${BAZEL_VERSION}-linux-arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${BAZEL_ARTIFACT} && \
    chmod +x /usr/bin/bazel

# Python tools
# Pinned versions of stuff we pull in
ENV AUTOPEP8_VERSION=1.4.4
ENV YAMLLINT_VERSION=1.29.0
ENV PIP_INSTALL_VERSION=21.0.1
ENV REQUESTS_VERSION=2.22.0
ENV PYTHON_PROTOBUF_VERSION=3.11.2
ENV PYYAML_VERSION=5.3.1
ENV JWCRYPTO_VERSION=0.7
ENV PYGITHUB_VERSION=1.57

# Install Python stuff
RUN python3 -m pip install --no-cache-dir --upgrade pip==${PIP_INSTALL_VERSION}
RUN python3 -m pip install --no-cache-dir --no-binary :all: autopep8==${AUTOPEP8_VERSION}
RUN python3 -m pip install --no-cache-dir yamllint==${YAMLLINT_VERSION}
RUN python3 -m pip install --no-cache-dir --ignore-installed requests==${REQUESTS_VERSION}
RUN python3 -m pip install --no-cache-dir protobuf==${PYTHON_PROTOBUF_VERSION}
RUN python3 -m pip install --no-cache-dir PyYAML==${PYYAML_VERSION}
RUN python3 -m pip install --no-cache-dir jwcrypto==${JWCRYPTO_VERSION}
RUN python3 -m pip install --no-cache-dir PyGithub==${PYGITHUB_VERSION}
RUN python3 -m pip install --user virtualenv

# Ruby tools
# Pinned versions of stuff we pull in
ENV FPM_VERSION=v1.15.1
ENV MDL_VERSION=0.12.0

# MDL
RUN gem install --no-wrappers --no-document mdl -v ${MDL_VERSION}

# hadolint ignore=DL3003,DL3028
RUN mkdir fpm && \
    cd fpm && \
    git init && \
    git remote add origin https://github.com/jordansissel/fpm && \
    git fetch --depth 1 origin ${FPM_VERSION} && \
    git checkout FETCH_HEAD && \
    make install && \
    cd .. && rm -rf fpm

# Rust (for WASM filters)
# Rust versions
ENV RUST_VERSION=1.68.2
ENV CARGO_HOME=/home/.cargo
ENV RUSTUP_HOME=/home/.rustup
ENV PATH=/rust/bin:$PATH
# hadolint ignore=DL4006
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y -v --default-toolchain ${RUST_VERSION} --profile minimal --component rustfmt clippy &&\
    /home/.cargo/bin/rustup default ${RUST_VERSION} &&\
    mv /home/.cargo/bin/* /usr/bin

# su-exec is used in place of complex sudo setup operations
RUN chmod u+sx /usr/bin/su-exec

COPY scripts/bashrc /home/.bashrc

# Workarounds for proxy and bazel
RUN useradd user && chmod 777 /home/user
ENV USER=user HOME=/home/user LANG=C.UTF-8

# Starting in Go 1.20, the standard library is not installed. https://go.dev/blog/go1.20
# Workarounds for fixing bazel build envoy error: '@go_sdk//:libs' does not produce any go_sdk libs files (expected .a)
##ENV GODEBUG=installgoroot=all
##RUN go install -ldflags="-s -w" std;

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
    mkdir -p /home/.cargo/registry && \
    mkdir -p /home/.helm && \
    mkdir -p /home/.gsutil

# TODO must sort out how to use uid mapping in docker so these don't need to be 777
# They are created as root 755.  As a result they are not writeable, which fails in
# the developer environment as a volume or bind mount inherits the permissions of
# the directory mounted rather then overriding with the permission of the volume file.
RUN chmod 777 /go && \
    chmod 777 /gocache && \
    chmod 777 /gobin && \
    chmod 777 /config && \
    chmod 777 /config/.docker && \
    chmod 777 /config/.config/gcloud && \
    chmod 777 /config/.kube && \
    chmod 777 /home/.cache && \
    chmod 777 /home/.cargo && \
    chmod 777 /home/.cargo/registry && \
    chmod 777 /home/.helm && \
    chmod 777 /home/.gsutil

# Clean up stuff we don't need in the final image
RUN rm -rf /usr/share/python \
           /usr/share/bash-completion \
           /usr/share/bug \
           /usr/share/doc \
           /usr/share/dh-python \
           /usr/share/locale \
           /usr/share/man \
           /tmp/*

RUN mkdir -p /work && chmod 777 /work
RUN git config --global --add safe.directory /work
WORKDIR /work

# Run dockerd in CI
COPY scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Run config setup in local environments
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]