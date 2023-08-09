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
ENV ISTIO_TOOLS_SHA=release-1.18

# Pinned versions of stuff we pull in
ENV BOM_VERSION=v0.5.1
ENV GCR_AUTH_VERSION=2.1.6
ENV GO_BINDATA_VERSION=v3.1.2
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV GOCOVMERGE_VERSION=b5bfa59ec0adc420475f97f89b58045c721d761c
ENV GOIMPORTS_VERSION=v0.1.0
ENV BENCHSTAT_VERSION=9c9101da8316
ENV GH_VERSION=2.32.1
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
ENV KUBECTL_VERSION=1.27.1
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION=v1.8.6
ENV PROTOC_GEN_SWAGGER_VERSION=v1.8.6
ENV PROTOC_GEN_VALIDATE_VERSION=v0.9.1
ENV PROTOC_VERSION=22.1
ENV PROTOLOCK_VERSION=v0.14.0
ENV PROTOTOOL_VERSION=v1.10.0
ENV SHELLCHECK_VERSION=v0.9.0
ENV SU_EXEC_VERSION=0.2
ENV YQ_VERSION=4.33.2
ENV KPT_VERSION=v0.39.3
ENV BUF_VERSION=v1.13.1
ENV GCLOUD_VERSION=425.0.0
ENV KUBETEST2_VERSION=b019714a389563c9a788f119f801520d059b6533
ENV COSIGN_VERSION=v2.0.1
ENV CRANE_VERSION=v0.14.0
ENV TRIVY_VERSION=0.43.1
ENV KUBECTX_VERSION=0.9.4

ENV GO111MODULE=on
ENV GOLANG_VERSION=1.19.10
##ENV GODEBUG=installgoroot=all
ENV GOPROXY="https://proxy.golang.org"

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
    wget -nv -O "/tmp/${GOLANG_GZ}" "https://go.dev/dl/${GOLANG_GZ}"; \
    tar -xzvf "/tmp/${GOLANG_GZ}" -C /tmp; \
    mv /tmp/go /usr/lib/golang; \
    ln -s /usr/lib/golang/bin/go /usr/local/bin/go;

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
RUN make
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
RUN rm -fr /usr/lib/golang/doc
RUN rm -fr /usr/lib/golang/test
RUN rm -fr /usr/lib/golang/bin/godoc

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
ENV NODEJS_VERSION=18.13.0
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

# General
ENV HOME=/home
ENV LANG=C.UTF-8

# Docker
ENV DOCKER_VERSION=3:24.0.5-1.el9
ENV DOCKER_CLI_VERSION=1:24.0.5-1.el9
ENV CONTAINERD_VERSION=1.6.21-3.1.el9
ENV DOCKER_BUILDX_VERSION=0.11.2-1.el9

# Rust
ENV RUST_VERSION=1.68.2

# Go support
ENV GO111MODULE=on
ENV GOPROXY="https://proxy.golang.org"
ENV GOSUMDB=sum.golang.org
ENV GOROOT=/usr/lib/golang
ENV GOPATH=/go
ENV GOCACHE=/gocache
ENV GOBIN=/usr/local/bin
ENV PATH=/usr/local/go/bin:/gobin:/usr/local/google-cloud-sdk/bin:$PATH

# LLVM support
ENV LLVM_DIRECTORY=/usr/lib/llvm
ENV PATH=${LLVM_DIRECTORY}/bin:$PATH

# Base OS
# required for binary tools: ca-certificates, gcc, glibc, git, iptables-nft, libtool-ltdl
# required for general build: make, wget, curl, openssh, rpm
# required for ruby: libcurl-devel
# required for python: python3, pkg-config
# required for ebpf build: clang,llvm,libbpf
# required for building maistra-2.4 envoy proxy: compat-openssl11
# required for building envoy proxy: libstdc++-static, libxcrypt-compat
# hadolint ignore=DL3008, DL3009
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False --allowerasing \
    ca-certificates-0:2022.2.54-90.2.el9_0 \
    curl-0:7.76.1-23.el9_2.2 \
    gnupg2-0:2.3.3-2.el9_0 \
    gcc-0:11.3.1-4.3.el9 \
    openssh-0:8.7p1-30.el9_2 \
    libtool-ltdl-0:2.4.6-45.el9 \
    glibc-0:2.34-60.el9 \
    make-1:4.3-7.el9 \
    pkgconf-pkg-config-0:1.7.3-10.el9 \
    python3-0:3.9.16-1.el9_2.1 \
    python3-pip \
    python3-setuptools-0:53.0.0-12.el9  \
    wget-0:1.21.1-7.el9 \
    jq-0:1.6-14.el9 \
    rsync-0:3.2.3-19.el9 \
    compat-openssl11-1:1.1.1k-4.el9_0 \
    libstdc++-static-0:11.3.1-4.3.el9 \
    libxcrypt-compat-0:4.4.18-3.el9 \
    git-0:2.39.3-1.el9_2 \
    iptables-nft-0:1.8.8-6.el9_1 \
    libcurl-devel-0:7.76.1-23.el9_2.2 \
    less-0:590-2.el9_2 \
    rpm-0:4.16.1.3-22.el9 \
    gettext-0:0.21-7.el9 \
    file-0:5.39-12.1.el9_2 \
    iproute-0:6.1.0-1.el9 \
    ipset-0:7.11-8.el9 \
    rsync-0:3.2.3-19.el9 \
    libbpf-2:1.0.0-2.el9 \
    net-tools-0:2.0-0.62.20160912git.el9 \
    ninja-build-0:1.10.2-6.el9 \
    sudo-0:1.9.5p2-9.el9 \
    autoconf-0:2.69-38.el9 \
    automake-0:1.16.2-6.el9 \
    cmake-0:3.20.2-8.el9 \
    python3-devel-0:3.9.16-1.el9_2.1 \
    unzip-0:6.0-56.el9

# maistra copr
RUN dnf -y copr enable @maistra/istio-2.3 centos-stream-8-x86_64 && \
    dnf -y install --setopt=install_weak_deps=False \
    binaryen emsdk

# Docker including docker-ce, docker-ce-cli, docker-buildx-plugin and containerd.io
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf -y upgrade --refresh
RUN dnf -y install --setopt=install_weak_deps=False docker-ce-"${DOCKER_VERSION}" docker-ce-cli-"${DOCKER_CLI_VERSION}" containerd.io-"${CONTAINERD_VERSION}" docker-buildx-plugin-"${DOCKER_BUILDX_VERSION}"

# Ruby tools
# Pinned versions of stuff we pull in
ENV FPM_VERSION=v1.15.1
ENV MDL_VERSION=0.12.0

# hadolint ignore=DL3008
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
    ruby-0:3.0.4-160.el9_0 \
    ruby-devel-0:3.0.4-160.el9_0

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

# Rust (for WASM filters)
ENV CARGO_HOME=/home/.cargo
ENV RUSTUP_HOME=/home/.rustup
# hadolint ignore=DL4006
RUN curl --proto '=https' -v --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y -v --default-toolchain ${RUST_VERSION} --profile minimal --component rustfmt clippy &&\
    /home/.cargo/bin/rustup default ${RUST_VERSION} &&\
    mv /home/.cargo/bin/* /usr/bin

# Create the file system
COPY --from=binary_tools_context /out/ /
COPY --from=binary_tools_context /usr/lib/golang /usr/lib/golang

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

# Workarounds for proxy and bazel
RUN useradd user && chmod 777 /home/user
ENV USER=user HOME=/home/user

RUN ln -s /usr/lib/golang/bin/go /usr/bin/go;

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
RUN dnf -y clean all
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

# Run dockerd in CI
COPY scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Run config setup in local environments
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
