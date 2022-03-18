FROM quay.io/centos/centos:stream8

# Versions
ENV ISTIO_TOOLS_SHA=release-1.12
ENV KUBECTL_VERSION="v1.20.4"
ENV HELM3_VERSION=v3.4.2
ENV KIND_VERSION="v0.11.1"
ENV AUTOPEP8_VERSION=1.4.4
ENV GOLANGCI_LINT_VERSION=v1.38.0
ENV HADOLINT_VERSION=v1.22.1
ENV MDL_VERSION=0.11.0
ENV YAMLLINT_VERSION=1.24.2
ENV GO_BINDATA_VERSION=v3.1.2
ENV PROTOC_VERSION=3.18.0
ENV GOIMPORTS_VERSION=v0.1.0
ENV GOGO_PROTOBUF_VERSION=v1.3.2
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV K8S_CODE_GENERATOR_VERSION=1.18.16
ENV LICENSEE_VERSION=9.15.1
ENV GOLANG_PROTOBUF_VERSION=v1.27.1
ENV FPM_VERSION=1.12.0
ENV SHELLCHECK_VERSION=v0.7.1
ENV JUNIT_MERGER_VERSION=adf1545b49509db1f83c49d1de90bbcb235642a8
ENV PROMU_VERSION=0.7.0
ENV VALE_VERSION="v2.1.1"
ENV HTML_PROOFER_VERSION=3.19.0
ENV COUNTERFEITER_VERSION=v6.2.3
ENV PROTOTOOL_VERSION=v1.10.0
ENV PROTOLOCK_VERSION=v0.14.0
ENV PROTOC_GEN_VALIDATE_VERSION=v0.6.1
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION=v1.8.6
ENV JSONNET_VERSION=v0.15.0
ENV JB_VERSION=v0.3.1
ENV PROTOC_GEN_SWAGGER_VERSION=v1.8.6
ENV GOCOVMERGE_VERSION=b5bfa59ec0adc420475f97f89b58045c721d761c
ENV BENCHSTAT_VERSION=9c9101da8316
ENV GH_VERSION=2.3.0
ENV K8S_TEST_INFRA_VERSION=aeeaba2bd2
ENV GCLOUD_VERSION=362.0.0
ENV SU_EXEC_VERSION=0.2
ENV BAZEL_VERSION=4.1.0

#this needs to match the version of Hugo used in maistra.io's netlify.toml file
ENV HUGO_VERSION="0.69.2"

ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO111MODULE=on
ENV GOBIN=/usr/local/bin
ENV GOSUMDB=sum.golang.org
ENV GOPATH=/go
ENV GOCACHE=/gocache

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

WORKDIR /root

# Install all dependencies available in RPM repos
RUN curl -sfL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core && \
    dnf -y config-manager --set-enabled powertools && \
    dnf -y install epel-release epel-next-release && \
    dnf -y copr enable jwendell/binaryen && \
    dnf -y copr enable jwendell/emsdk && \
    dnf -y module reset ruby nodejs && dnf -y module enable ruby:2.7 nodejs:12 && dnf -y module install ruby nodejs && \
    dnf -y install --nodocs --setopt=install_weak_deps=False \
                   git make libtool patch which ninja-build golang xz redhat-rpm-config \
                   autoconf automake libtool cmake python2 python3 \
                   gcc-toolset-9 gcc-toolset-9-libatomic-devel gcc-toolset-9-annobin \
                   gcc-toolset-11 gcc-toolset-11-libatomic-devel gcc-toolset-11-annobin-plugin-gcc \
                   java-11-openjdk-devel jq file diffutils lbzip2 annobin-annocheck \
                   clang llvm lld ruby-devel zlib-devel openssl-devel python2-setuptools \
                   binaryen emsdk docker-ce python3-pip rubygems npm rpm-build && \
    dnf -y clean all

# Build and install a bunch of Go tools
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${GOLANG_PROTOBUF_VERSION} && \
    go install github.com/gogo/protobuf/protoc-gen-gofast@${GOGO_PROTOBUF_VERSION} && \
    go install github.com/gogo/protobuf/protoc-gen-gogofast@${GOGO_PROTOBUF_VERSION} && \
    go install github.com/gogo/protobuf/protoc-gen-gogofaster@${GOGO_PROTOBUF_VERSION} && \
    go install github.com/gogo/protobuf/protoc-gen-gogoslick@${GOGO_PROTOBUF_VERSION} && \
    \
    go install github.com/uber/prototool/cmd/prototool@${PROTOTOOL_VERSION} && \
    go install github.com/nilslice/protolock/cmd/protolock@${PROTOLOCK_VERSION} && \
    go install golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION} && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION} && \
    go install github.com/go-bindata/go-bindata/go-bindata@${GO_BINDATA_VERSION} && \
    go install github.com/envoyproxy/protoc-gen-validate@${PROTOC_GEN_VALIDATE_VERSION} && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@${PROTOC_GEN_GRPC_GATEWAY_VERSION} && \
    go install github.com/google/go-jsonnet/cmd/jsonnet@${JSONNET_VERSION} && \
    go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@${JB_VERSION} && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@${PROTOC_GEN_SWAGGER_VERSION} && \
    go install github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION} && \
    go install sigs.k8s.io/kind@${KIND_VERSION} && \
    go install github.com/wadey/gocovmerge@${GOCOVMERGE_VERSION} && \
    go install github.com/imsky/junit-merger/src/junit-merger@${JUNIT_MERGER_VERSION} && \
    go install golang.org/x/perf/cmd/benchstat@${BENCHSTAT_VERSION} && \
    \
    go install istio.io/tools/cmd/protoc-gen-docs@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/annotations_prep@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/cue-gen@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/protoc-gen-deepcopy@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/protoc-gen-jsonshim@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/kubetype-gen@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA} && \
    go install istio.io/tools/cmd/gen-release-notes@${ISTIO_TOOLS_SHA} && \
    \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/defaulter-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/client-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/lister-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/informer-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/deepcopy-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/go-to-protobuf@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    \
    go install github.com/mikefarah/yq/v3@latest && mv /usr/local/bin/yq /usr/local/bin/yq-go && \
    \
    rm -rf /root/* /root/.cache /tmp/*

# pr-creator
RUN git clone --branch master --single-branch https://github.com/kubernetes/test-infra.git /root/test-infra && \
    cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
    go install ./robots/pr-creator && \
    go install ./prow/cmd/peribolos && \
    go install ./prow/cmd/checkconfig && \
    go install ./pkg/benchmarkjunit && \
    rm -rf /root/* /root/.cache /tmp/*

# GH CLI
RUN curl -sfLO https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz && \
    tar zxf gh_${GH_VERSION}_linux_amd64.tar.gz && \
    mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin && chown root.root /usr/local/bin/gh && \
    rm -rf /root/* /root/.cache /tmp/*

# Python tools
RUN pip3 install --no-binary :all: autopep8==${AUTOPEP8_VERSION} && \
    pip3 install yamllint==${YAMLLINT_VERSION} && \
    pip3 install yq && mv /usr/local/bin/yq /usr/local/bin/yq-python && \
    ln -s /usr/local/bin/yq-go /usr/local/bin/yq && \
    rm -rf /root/* /root/.cache /tmp/*

# Ruby tools
# FIXME: I'm getting:
#   ERROR:  While executing gem ... (ArgumentError)
#      Malformed version number string linux
# On licensee
RUN echo MDL && gem install --no-wrappers --no-document mdl -v ${MDL_VERSION} && \
    echo HTML-PROOFER && gem install --no-wrappers --no-document html-proofer -v ${HTML_PROOFER_VERSION} && \
    echo FPM && gem install --no-wrappers --no-document fpm -v ${FPM_VERSION} && \
    rm -rf /root/* /root/.cache /root/.gem /tmp/*
#    echo LICENSEE && gem install --no-wrappers --no-document licensee -v ${LICENSEE_VERSION} && \

# ShellCheck linter
RUN curl -sfL https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJ shellcheck-${SHELLCHECK_VERSION}/shellcheck --strip=1 && \
    mv shellcheck /usr/bin/shellcheck

# Other lint tools
RUN curl -sfL https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 -o /usr/bin/hadolint && \
    chmod +x /usr/bin/hadolint

# Helm
RUN curl -sfL https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1 && \
    mv helm /usr/local/bin/helm && chown root.root /usr/local/bin/helm && ln -s /usr/local/bin/helm /usr/local/bin/helm3

# Hugo
RUN curl -sfL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz | tar -xz hugo && mv hugo /usr/local/bin

# Kubectl
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Docs
RUN curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o ./vale.sh && \
    chmod +x ./vale.sh && ./vale.sh -b /usr/local/bin ${VALE_VERSION} && \
    rm -rf ./vale.sh /root/* /root/.cache /tmp/*

# Protoc
RUN curl -sfLO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    mv bin/protoc /usr/local/bin && \
    rm -rf /root/* /root/.cache /tmp/*

# Yarn
RUN npm install --global yarn && \
    rm -rf /root/* /root/.cache /root/.npm /tmp/*

# Promu
RUN curl -sfLO https://github.com/prometheus/promu/releases/download/v${PROMU_VERSION}/promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    tar -zxvf promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    mv promu-${PROMU_VERSION}.linux-amd64/promu /usr/local/bin && chown root.root /usr/local/bin/promu && \
    rm -rf /root/* /root/.cache /tmp/*

# Google cloud tools
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz

# su-exec
RUN mkdir /tmp/su-exec && cd /tmp/su-exec && \
    curl -sfL -o /tmp/su-exec/su-exec.tar.gz https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz && \
    tar xfz /tmp/su-exec/su-exec.tar.gz && \
    cd su-exec-${SU_EXEC_VERSION} && make && \
    cp -a su-exec /usr/local/bin && \
    chmod u+sx /usr/local/bin/su-exec && \
    rm -rf /tmp/su-exec

# Bazel
RUN curl -o /usr/bin/bazel -Ls https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64 && \
    chmod +x /usr/bin/bazel

# Rust (for WASM filters)
ENV CARGO_HOME "/rust"
ENV RUSTUP_HOME "/rust"
RUN mkdir /rust && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    /rust/bin/rustup target add wasm32-unknown-unknown
ENV PATH=/usr/local/google-cloud-sdk/bin:/rust/bin:$PATH

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work

# Workarounds for proxy and bazel
RUN useradd user && chmod 777 /home/user
ENV USER=user HOME=/home/user
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt

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
RUN chmod 777 /go && \
    chmod 777 /gocache && \
    chmod 777 /gobin && \
    chmod 777 /config && \
    chmod 777 /config/.docker && \
    chmod 777 /config/.config/gcloud && \
    chmod 777 /config/.kube && \
    chmod 777 /home/.cache && \
    chmod 777 /home/.helm && \
    chmod 777 /home/.gsutil

ADD scripts/prow-entrypoint-main.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Run config setup in local environments
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
