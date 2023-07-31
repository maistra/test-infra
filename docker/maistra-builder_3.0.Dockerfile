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

################
# Binary tools
################
ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi:9.2-696
# hadolint ignore=DL3006
FROM ${BASE_IMAGE} as binary_tools_context

ARG TARGETARCH

RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac;

# Versions
# Istio tools SHA that we use for this image
ENV ISTIO_TOOLS_SHA=release-1.19

# Pinned versions of stuff we pull in
ENV BENCHSTAT_VERSION=9c9101da8316
ENV BOM_VERSION=v0.5.1
ENV BUF_VERSION=v1.24.0
ENV COSIGN_VERSION=v2.1.1
ENV CRANE_VERSION=v0.15.2
ENV GCLOUD_VERSION=437.0.1
ENV GCR_AUTH_VERSION=2.1.6
ENV GH_VERSION=2.32.1
ENV GOCOVMERGE_VERSION=b5bfa59ec0adc420475f97f89b58045c721d761c
ENV GOIMPORTS_VERSION=v0.9.1
# When updating the golangci version, you may want to update the common-files config/.golangci* files as well.
ENV GOLANGCI_LINT_VERSION=v1.53.2
ENV GOLANG_GRPC_PROTOBUF_VERSION=v1.3.0
ENV GOLANG_PROTOBUF_VERSION=v1.31.0
ENV GO_BINDATA_VERSION=v3.1.2
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV HADOLINT_VERSION=v2.10.0
ENV HELM3_VERSION=v3.12.2
ENV HUGO_VERSION=0.115.3
ENV JB_VERSION=v0.3.1
ENV JSONNET_VERSION=v0.15.0
ENV JUNIT_MERGER_VERSION=adf1545b49509db1f83c49d1de90bbcb235642a8
ENV K8S_CODE_GENERATOR_VERSION=1.27.1
# From 7/6/2023
ENV K8S_TEST_INFRA_VERSION=91ecbd6a270f879e309760d65eccc60f466e726b
ENV KIND_VERSION=v0.20.0
ENV KPT_VERSION=v1.0.0-beta.35
ENV KUBECTL_VERSION=1.27.3
ENV KUBECTX_VERSION=0.9.4
ENV KUBETEST2_VERSION=b019714a389563c9a788f119f801520d059b6533
# TODO: switch to v0.4.0 when its out; we depend on some bug fixes since v0.3.0
ENV OTEL_CLI_VERSION=159cd1ec2e3f992e5f963dc70269b068c1038738
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION=v1.16.0
ENV PROTOC_GEN_VALIDATE_VERSION=1.0.1
ENV PROTOC_VERSION=23.4
ENV PROTOLOCK_VERSION=v0.16.0
ENV SHELLCHECK_VERSION=v0.9.0
ENV SU_EXEC_VERSION=0.3.1
ENV TRIVY_VERSION=0.43.1
ENV YQ_VERSION=4.34.2

ENV GO111MODULE=on
ENV GOLANG_VERSION=1.20.6
ENV GOPROXY="https://proxy.golang.org,direct"

WORKDIR /tmp
ENV GOPATH=/tmp/go

ENV OUTDIR=/out
RUN mkdir -p ${OUTDIR}/usr/bin
RUN mkdir -p ${OUTDIR}/usr/local

# Update distro and install dependencies
# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False --allowerasing \
    make \
    unzip \
    xz \
    wget \
    curl \
    clang \
    llvm

# Currently the latest golang version is 1.19 from UBI9 base image default repo.
# Install golang 1.20 from go.dev/dl
# hadolint ignore=DL3008
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) GOLANG_GZ=go${GOLANG_VERSION}.linux-amd64.tar.gz;; \
        aarch64) GOLANG_GZ=go${GOLANG_VERSION}.linux-arm64.tar.gz;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -nv -O "/tmp/${GOLANG_GZ}" "https://go.dev/dl/${GOLANG_GZ}"; \
    tar -xzvf "/tmp/${GOLANG_GZ}" -C /tmp; \
    mv /tmp/go /usr/local/go; \
    ln -s /usr/local/go/bin/go /usr/local/bin/go;

# Install protoc
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip;; \
        aarch64) PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-aarch_64.zip;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -nv -O "/tmp/${PROTOC_ZIP}" "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}"; \
    unzip "/tmp/${PROTOC_ZIP}"; \
    mv /tmp/bin/protoc ${OUTDIR}/usr/bin; \
    chmod +x ${OUTDIR}/usr/bin/protoc

# Install gh
RUN dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
RUN dnf -y install --setopt=install_weak_deps=False \
    gh-${GH_VERSION}-1
RUN mv /usr/bin/gh ${OUTDIR}/usr/bin

# Install protoc-gen-validate
RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) PROTOC_GEN_VALIDATE_GZ=protoc-gen-validate_${PROTOC_GEN_VALIDATE_VERSION}_linux_amd64.tar.gz;; \
        aarch64) PROTOC_GEN_VALIDATE_GZ=protoc-gen-validate_${PROTOC_GEN_VALIDATE_VERSION}_linux_arm64.tar.gz;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    \
    wget -nv -O "/tmp/${PROTOC_GEN_VALIDATE_GZ}" "https://github.com/bufbuild/protoc-gen-validate/releases/download/v${PROTOC_GEN_VALIDATE_VERSION}/${PROTOC_GEN_VALIDATE_GZ}"; \
    tar -xzvf "/tmp/${PROTOC_GEN_VALIDATE_GZ}" -C /tmp; \
    mv /tmp/protoc-gen-validate ${OUTDIR}/usr/bin; \
    mv /tmp/protoc-gen-validate-go ${OUTDIR}/usr/bin; \
    chmod +x ${OUTDIR}/usr/bin/protoc-gen-validate; \
    chmod +x ${OUTDIR}/usr/bin/protoc-gen-validate-go

# Build and install a bunch of Go tools
RUN go install -ldflags="-s -w" google.golang.org/protobuf/cmd/protoc-gen-go@${GOLANG_PROTOBUF_VERSION}
RUN go install -ldflags="-s -w" google.golang.org/grpc/cmd/protoc-gen-go-grpc@${GOLANG_GRPC_PROTOBUF_VERSION}
RUN go install -ldflags="-s -w" github.com/nilslice/protolock/cmd/protolock@${PROTOLOCK_VERSION}
RUN go install -ldflags="-s -w" golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION}
RUN go install -ldflags="-s -w" github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION}
RUN go install -ldflags="-s -w" github.com/go-bindata/go-bindata/go-bindata@${GO_BINDATA_VERSION}
RUN go install -ldflags="-s -w" github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@${PROTOC_GEN_GRPC_GATEWAY_VERSION}
RUN go install -ldflags="-s -w" github.com/google/go-jsonnet/cmd/jsonnet@${JSONNET_VERSION}
RUN go install -ldflags="-s -w" github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@${JB_VERSION}
RUN go install -ldflags="-s -w" github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION}
RUN go install -ldflags="-s -w" sigs.k8s.io/bom/cmd/bom@${BOM_VERSION}
RUN go install -ldflags="-s -w" sigs.k8s.io/kind@${KIND_VERSION}
RUN go install -ldflags="-s -w" github.com/wadey/gocovmerge@${GOCOVMERGE_VERSION}
RUN go install -ldflags="-s -w" github.com/imsky/junit-merger/src/junit-merger@${JUNIT_MERGER_VERSION}
RUN go install -ldflags="-s -w" golang.org/x/perf/cmd/benchstat@${BENCHSTAT_VERSION}
RUN go install -ldflags="-s -w" github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION}
RUN go install -ldflags="-s -w" github.com/equinix-labs/otel-cli@${OTEL_CLI_VERSION}
# Install latest version of Istio-owned tools in this release
# new module in istio.io/tools release-1.19 istio.io/tools/cmd/org-gen
RUN go install -ldflags="-s -w" \
  istio.io/tools/cmd/protoc-gen-docs@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/annotations_prep@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/cue-gen@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/protoc-gen-golang-deepcopy@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/protoc-gen-golang-jsonshim@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/kubetype-gen@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/gen-release-notes@${ISTIO_TOOLS_SHA} \
  istio.io/tools/cmd/org-gen@${ISTIO_TOOLS_SHA}
RUN go install -ldflags="-s -w" \
  k8s.io/code-generator/cmd/applyconfiguration-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/defaulter-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/client-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/lister-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/informer-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/deepcopy-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} \
  k8s.io/code-generator/cmd/go-to-protobuf@kubernetes-${K8S_CODE_GENERATOR_VERSION}
RUN go install -ldflags="-s -w" \
    sigs.k8s.io/kubetest2@${KUBETEST2_VERSION} \
    sigs.k8s.io/kubetest2/kubetest2-gke@${KUBETEST2_VERSION} \
    sigs.k8s.io/kubetest2/kubetest2-tester-exec@${KUBETEST2_VERSION}

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
RUN wget -nv -O "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz"
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
    wget -nv -O ${OUTDIR}/usr/bin/hadolint https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/${HADOLINT_BINARY}; \
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
    wget -nv -O /tmp/${HUGO_TAR} https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR}; \
    tar -xzvf /tmp/${HUGO_TAR} -C /tmp; \
    mv /tmp/hugo ${OUTDIR}/usr/bin

# Helm version 3
ADD https://get.helm.sh/helm-${HELM3_VERSION}-linux-${TARGETARCH}.tar.gz /tmp
RUN mkdir /tmp/helm3
RUN tar -xf /tmp/helm-${HELM3_VERSION}-linux-${TARGETARCH}.tar.gz -C /tmp/helm3
RUN mv /tmp/helm3/linux-${TARGETARCH}/helm ${OUTDIR}/usr/bin/helm3
RUN ln ${OUTDIR}/usr/bin/helm3 ${OUTDIR}/usr/bin/helm

# yq doesn't support go modules, so install the binary instead
ADD https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} /tmp
RUN mv /tmp/yq_linux_${TARGETARCH} ${OUTDIR}/usr/bin/yq
RUN chmod 555 ${OUTDIR}/usr/bin/yq

# Kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl ${OUTDIR}/usr/bin/kubectl
RUN chmod 555 ${OUTDIR}/usr/bin/kubectl

# Buf
RUN wget -nv -O "${OUTDIR}/usr/bin/buf" "https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-$(uname -m)" && \
    chmod 555 "${OUTDIR}/usr/bin/buf"

# Install su-exec which is a tool that operates like sudo without the overhead
ADD https://github.com/NobodyXu/su-exec/archive/refs/tags/v${SU_EXEC_VERSION}.tar.gz /tmp
RUN tar -xzvf v${SU_EXEC_VERSION}.tar.gz
WORKDIR /tmp/su-exec-${SU_EXEC_VERSION}
# Setting LDFLAGS is needed here, upstream uses '--icf=all' which our linker  doesn't have
RUN LDFLAGS="-fvisibility=hidden -Wl,-O2 -Wl,--discard-all -Wl,--strip-all -Wl,--as-needed -Wl,--gc-sections" make
RUN cp -a su-exec ${OUTDIR}/usr/bin

ADD https://github.com/GoogleContainerTools/kpt/releases/download/${KPT_VERSION}/kpt_linux_${TARGETARCH} ${OUTDIR}/usr/bin/kpt
RUN chmod 555 ${OUTDIR}/usr/bin/kpt

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
    wget -nv "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_TAR_FILE}"; \
    tar -xzvf ."/${GCLOUD_TAR_FILE}" -C "${OUTDIR}/usr/local" && rm "${GCLOUD_TAR_FILE}"; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install beta --quiet; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install alpha --quiet; \
    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install gke-gcloud-auth-plugin --quiet; \
    rm -rf ${OUTDIR}/usr/local/google-cloud-sdk/.install/.backup \
    rm -rf ${OUTDIR}/usr/local/google-cloud-sdk/bin/anthoscli

# Install cosign (for signing build artifacts) and verify signature
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -eux; \
    wget -nv -O /tmp/cosign https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${TARGETARCH} \
    && wget -nv -O - https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${TARGETARCH}.sig | base64 -d > /tmp/cosign.sig \
    && wget -nv -O /tmp/cosign-pubkey https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub \
    && openssl dgst -sha256 -verify /tmp/cosign-pubkey -signature /tmp/cosign.sig /tmp/cosign \
    && chmod +x /tmp/cosign \
    && mv /tmp/cosign ${OUTDIR}/usr/bin/ || exit 1

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
    wget -nv -O "/tmp/${TRVIY_DEB_NAME}" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${TRVIY_DEB_NAME}"; \
    dnf install -y --setopt=install_weak_deps=False "/tmp/${TRVIY_DEB_NAME}"; \
    rm "/tmp/${TRVIY_DEB_NAME}"; \
    mv /usr/bin/trivy ${OUTDIR}/usr/bin/

# Install kubectx and kubens
ADD https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx /tmp
RUN mv /tmp/kubectx ${OUTDIR}/usr/bin/kubectx
RUN chmod 555 ${OUTDIR}/usr/bin/kubectx
ADD https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens /tmp
RUN mv /tmp/kubens ${OUTDIR}/usr/bin/kubens
RUN chmod 555 ${OUTDIR}/usr/bin/kubens

# Move Go tools to their final location
RUN mv /tmp/go/bin/* ${OUTDIR}/usr/bin

# Cleanup stuff we don't need in the final image
RUN rm -fr /usr/local/go/doc
RUN rm -fr /usr/local/go/test
RUN rm -fr /usr/local/go/api
RUN rm -fr /usr/local/go/bin/godoc
RUN rm -fr /usr/local/go/bin/gofmt

#############
# Node.js
#############
FROM registry.access.redhat.com/ubi9/ubi:9.2-696 as nodejs_tools_context

WORKDIR /node

# Pinned versions of stuff we pull in
ENV BABEL_CLI_VERSION=v7.17.10
ENV BABEL_CORE_VERSION=v7.18.2
ENV BABEL_POLYFILL_VERSION=v7.12.1
ENV BABEL_PRESET_ENV=v7.18.2
ENV BABEL_PRESET_MINIFY_VERSION=v0.5.2
ENV LINKINATOR_VERSION=v2.0.5
ENV MARKDOWN_SPELLCHECK_VERSION=v1.3.1
ENV NODEJS_VERSION=18.16.0
ENV SASS_LINT_VERSION=v1.13.1
ENV SASS_VERSION=v1.52.1
ENV SVGO_VERSION=v1.3.2
ENV SVGSTORE_CLI_VERSION=v1.3.2
ENV TSLINT_VERSION=v6.1.3
ENV TYPESCRIPT_VERSION=v4.7.2

RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    wget ca-certificates

RUN set -eux; \
    case $(uname -m) in \
        x86_64) NODEJS_TAR=node-v${NODEJS_VERSION}-linux-x64.tar.gz;; \
        aarch64) NODEJS_TAR=node-v${NODEJS_VERSION}-linux-arm64.tar.gz;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac; \
    wget -nv -O /tmp/${NODEJS_TAR} https://nodejs.org/download/release/v${NODEJS_VERSION}/${NODEJS_TAR}; \
    tar -xzf /tmp/${NODEJS_TAR} --strip-components=1 -C /usr/local

ADD https://nodejs.org/download/release/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-headers.tar.gz /tmp
RUN tar -xzf /tmp/node-v${NODEJS_VERSION}-headers.tar.gz --strip-components=1 -C /usr/local

RUN npm init -y
RUN npm install --omit=dev --global \
    sass@"${SASS_VERSION}" \
    sass-lint@"${SASS_LINT_VERSION}" \
    typescript@"${TYPESCRIPT_VERSION}" \
    tslint@"${TSLINT_VERSION}" \
    markdown-spellcheck@"${MARKDOWN_SPELLCHECK_VERSION}" \
    svgstore-cli@"${SVGSTORE_CLI_VERSION}" \
    svgo@"${SVGO_VERSION}" \
    @babel/core@"${BABEL_CORE_VERSION}" \
    @babel/cli@"${BABEL_CLI_VERSION}" \
    @babel/preset-env@"${BABEL_PRESET_ENV_VERSION}" \
    linkinator@"${LINKINATOR_VERSION}"

RUN npm install --omit=dev --save-dev \
    babel-preset-minify@${BABEL_PRESET_MINIFY_VERSION}

RUN npm install --save-dev \
    @babel/polyfill@${BABEL_POLYFILL_VERSION}

# Clean up stuff we don't need in the final image
RUN rm -rf /usr/local/sbin
RUN rm -rf /usr/local/share

#############
# Base OS
#############

FROM registry.access.redhat.com/ubi9/ubi:9.2-696 as base_os_context

ENV DOCKER_VERSION=3:24.0.5-1.el9
ENV DOCKER_CLI_VERSION=1:24.0.5-1.el9
ENV CONTAINERD_VERSION=1.6.21-3.1.el9
ENV DOCKER_BUILDX_VERSION=0.11.2-1.el9
ENV RUST_VERSION=1.71.0

ENV OUTDIR=/out

# required for binary tools: ca-certificates, glibc, git, iptables-nft, libtool-ltdl, less
# required for general build: make, wget, curl, openssh, rpm
# required for ruby: libcurl-devel
# required for python: python3, pkg-config
# required for ebpf build: clang,llvm,libbpf
# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False --allowerasing \
    ca-certificates \
    curl \
    gnupg2 \
    ca-certificates \
    cmake \
    cmake-data \
    git \
    openssh \
    iptables-nft \
    libtool-ltdl \
    glibc \
    libcurl-devel \
    less \
    make \
    pkg-config \
    python3 \
    python3-setuptools \
    wget \
    rpm \
    jq \
    gettext \
    file \
    iproute \
    ipset \
    rsync \
    clang \
    llvm \
    libbpf \
    net-tools \
    ninja-build \
    sudo

# Docker including docker-ce, docker-ce-cli, and containerd.io
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf -y upgrade --refresh
RUN dnf -y install --setopt=install_weak_deps=False docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_CLI_VERSION}" containerd.io-"${CONTAINERD_VERSION}" docker-buildx-plugin-"${DOCKER_BUILDX_VERSION}"

# Rust (for WASM filters)
ENV CARGO_HOME=/home/.cargo
ENV RUSTUP_HOME=/home/.rustup
# hadolint ignore=DL4006
RUN curl --proto '=https' -v --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y -v --default-toolchain ${RUST_VERSION} --profile minimal --component rustfmt clippy &&\
    /home/.cargo/bin/rustup default ${RUST_VERSION} &&\
    mv /home/.cargo/bin/* /usr/bin

# Clean up stuff we don't need in the final image
RUN dnf -y clean all
RUN rm -fr /usr/share/python
RUN rm -fr /usr/share/bash-completion
RUN rm -fr /usr/share/bug
RUN rm -fr /usr/share/doc
RUN rm -fr /usr/share/dh-python
RUN rm -fr /usr/share/locale
RUN rm -fr /usr/share/man
RUN rm -fr /tmp/*

# Run dockerd in CI
COPY scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Run config setup in local environments
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

##############
# Clang+LLVM
##############

# hadolint ignore=DL3006
FROM registry.access.redhat.com/ubi9/ubi:9.2-696 AS clang_context

# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    xz \
    wget \
    ca-certificates

# Stick with clang 14.0.6
ENV LLVM_VERSION=14.0.6
ENV LLVM_BASE_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}
ENV LLVM_DIRECTORY=/usr/lib/llvm

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
    wget -nv ${LLVM_BASE_URL}/${LLVM_ARTIFACT}.tar.xz; \
    tar -xJf ${LLVM_ARTIFACT}.tar.xz -C /tmp; \
    mkdir -p ${LLVM_DIRECTORY}; \
    mv /tmp/${LLVM_ARCHIVE}/* ${LLVM_DIRECTORY}/

###########
# Bazel
###########

# hadolint ignore=DL3006
FROM registry.access.redhat.com/ubi9/ubi:9.2-696 AS bazel_context

ARG TARGETARCH

RUN set -eux; \
    \
    case $(uname -m) in \
        x86_64) TARGETARCH=amd64;; \
        aarch64) TARGETARCH=arm64;; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac;

ENV BAZELISK_VERSION="v1.16.0"
ENV BAZELISK_BASE_URL="https://github.com/bazelbuild/bazelisk/releases/download"
ENV BAZELISK_BIN="bazelisk-linux-${TARGETARCH}"
ENV BAZELISK_URL="${BAZELISK_BASE_URL}/${BAZELISK_VERSION}/${BAZELISK_BIN}"

# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    wget \
    ca-certificates

RUN wget -nv ${BAZELISK_URL}
RUN chmod +x ${BAZELISK_BIN}
RUN mv ${BAZELISK_BIN} /usr/local/bin/bazel

##############
# Final image
##############

# Prepare final output image
FROM registry.access.redhat.com/ubi9/ubi:9.2-696 as build_tools

WORKDIR /

# Version from build arguments
ARG VERSION

# Docker
ENV DOCKER_VERSION=3:24.0.5-1.el9
ENV DOCKER_CLI_VERSION=1:24.0.5-1.el9
ENV CONTAINERD_VERSION=1.6.21-3.1.el9

# General
ENV HOME=/home
ENV LANG=C.UTF-8

# Go support
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org
ENV GOSUMDB=sum.golang.org
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV GOCACHE=/gocache
ENV GOBIN=/gobin
ENV PATH=/usr/local/go/bin:/gobin:/usr/local/google-cloud-sdk/bin:$PATH

# LLVM support
ENV LLVM_DIRECTORY=/usr/lib/llvm
ENV PATH=${LLVM_DIRECTORY}/bin:$PATH

# required for binary tools: ca-certificates, gcc, glibc, git, iptables-nft, libtool-ltdl
# required for general build: make, wget, curl, openssh
# required for python: python3, pkg-config
# hadolint ignore=DL3008, DL3009
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False --allowerasing \
    ca-certificates \
    curl \
    gnupg2 \
    ca-certificates \
    gcc \
    openssh \
    libtool-ltdl \
    glibc \
    make \
    pkg-config \
    python3 \
    python3-pip \
    python3-setuptools \
    wget \
    jq \
    rsync

# maistra copr
RUN dnf -y copr enable @maistra/istio-2.3 centos-stream-8-x86_64 && \
    dnf -y install --setopt=install_weak_deps=False \
    binaryen emsdk 

# Build git from source. Golang now requires a recent git version
# hadolint ignore=DL3003,DL3009,DL4001
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    openssl-devel \
    libcurl-devel \
    expat-devel \
    zlib-devel \
    gettext \
    unzip && \
    wget -q https://github.com/git/git/archive/v2.39.1.zip -O git.zip && \
    unzip git.zip && \
    cd git-* && \
    make prefix=/usr/local all && \
    make prefix=/usr/local install && \
    cd .. && rm -rf git-*

# Docker including docker-ce, docker-ce-cli, and containerd.io
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf -y upgrade --refresh
RUN dnf -y install --setopt=install_weak_deps=False docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_CLI_VERSION}" containerd.io-"${CONTAINERD_VERSION}"

# Run dockerd in CI
COPY scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Ruby tools
# Pinned versions of stuff we pull in
ENV FPM_VERSION=v1.15.1
ENV MDL_VERSION=0.12.0

# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    ruby-0:3.0.4-160.el9_0 \
    ruby-devel-0:3.0.4-160.el9_0

# Install istio.io verification tools
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

# Python tools
# Pinned versions of stuff we pull in
ENV AUTOPEP8_VERSION=2.0.2
ENV YAMLLINT_VERSION=1.32.0
ENV PIP_INSTALL_VERSION=23.1.2
ENV REQUESTS_VERSION=2.31.0
ENV PYTHON_PROTOBUF_VERSION=4.23.2
ENV PYYAML_VERSION=6.0
ENV JWCRYPTO_VERSION=1.5.0
ENV PYGITHUB_VERSION=1.58.2

# Install Python stuff
RUN python3 -m pip install --no-cache-dir --upgrade pip==${PIP_INSTALL_VERSION}
RUN python3 -m pip install --no-cache-dir --no-binary :all: autopep8==${AUTOPEP8_VERSION}
RUN python3 -m pip install --no-cache-dir yamllint==${YAMLLINT_VERSION}
RUN python3 -m pip install --no-cache-dir --ignore-installed requests==${REQUESTS_VERSION}
RUN python3 -m pip install --no-cache-dir protobuf==${PYTHON_PROTOBUF_VERSION}
RUN python3 -m pip install --no-cache-dir PyYAML==${PYYAML_VERSION}
RUN python3 -m pip install --no-cache-dir jwcrypto==${JWCRYPTO_VERSION}
RUN python3 -m pip install --no-cache-dir PyGithub==${PYGITHUB_VERSION}

# binary dependencies to build envoy at v1.12.0
# https://github.com/envoyproxy/envoy/blob/v1.12.0/bazel/README.md
# hadolint ignore=DL3008,DL3009
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    autoconf \
    automake \
    cmake \
    libtool \
    ninja-build \
    python3-devel \
    python3-pip \
    unzip
RUN python3 -m pip install --user virtualenv

# Create the file system
COPY --from=base_os_context / /
COPY --from=binary_tools_context /out/ /
COPY --from=binary_tools_context /usr/local/go /usr/local/go

COPY --from=nodejs_tools_context /usr/local/bin /usr/local/bin
COPY --from=nodejs_tools_context /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=nodejs_tools_context /node/node_modules /node_modules

COPY --from=bazel_context /usr/local/bin /usr/local/bin
COPY --from=clang_context ${LLVM_DIRECTORY}/lib ${LLVM_DIRECTORY}/lib
COPY --from=clang_context ${LLVM_DIRECTORY}/bin ${LLVM_DIRECTORY}/bin
COPY --from=clang_context ${LLVM_DIRECTORY}/include ${LLVM_DIRECTORY}/include

RUN echo "${LLVM_DIRECTORY}/lib" | tee /etc/ld.so.conf.d/llvm.conf
RUN ldconfig

# su-exec is used in place of complex sudo setup operations
RUN chmod u+sx /usr/bin/su-exec

COPY scripts/bashrc /home/.bashrc

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
RUN rm -rf /var/lib/apt/lists/*
RUN rm -fr /usr/share/python
RUN rm -fr /usr/share/bash-completion
RUN rm -fr /usr/share/bug
RUN rm -fr /usr/share/doc
RUN rm -fr /usr/share/dh-python
RUN rm -fr /usr/share/locale
RUN rm -fr /usr/share/man
RUN rm -fr /tmp/*

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work

# Run config setup in local environments
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
