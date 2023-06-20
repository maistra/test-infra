FROM quay.io/centos/centos:stream8

# Versions
ENV ISTIO_TOOLS_SHA=release-1.18
ENV KUBECTL_VERSION=1.27.1
ENV HELM3_VERSION=v3.11.2
ENV KIND_VERSION=v0.18.0
ENV AUTOPEP8_VERSION=1.4.4
ENV GOLANGCI_LINT_VERSION=v1.51.2
ENV HADOLINT_VERSION=v2.12.0
ENV MDL_VERSION=0.12.0
ENV YAMLLINT_VERSION=1.24.2
ENV GO_BINDATA_VERSION=v3.1.2
ENV PROTOC_VERSION=22.1
ENV GOIMPORTS_VERSION=v0.1.0
ENV GOGO_PROTOBUF_VERSION=v1.3.2
ENV GO_JUNIT_REPORT_VERSION=df0ed838addb0fa189c4d76ad4657f6007a5811c
ENV K8S_CODE_GENERATOR_VERSION=1.27.1
ENV LICENSEE_VERSION=9.15.1
ENV GOLANG_PROTOBUF_VERSION=v1.30.0
ENV GOLANG_GRPC_PROTOBUF_VERSION=v1.2.0
ENV SHELLCHECK_VERSION=v0.9.0
ENV JUNIT_MERGER_VERSION=adf1545b49509db1f83c49d1de90bbcb235642a8
ENV PROMU_VERSION=0.7.0
ENV VALE_VERSION="v2.1.1"
ENV HTML_PROOFER_VERSION=3.19.0
ENV COUNTERFEITER_VERSION=v6.2.3
ENV PROTOTOOL_VERSION=v1.10.0
ENV PROTOLOCK_VERSION=v0.14.0
ENV PROTOC_GEN_VALIDATE_VERSION=v0.9.1
ENV PROTOC_GEN_GRPC_GATEWAY_VERSION=v1.8.6
ENV JSONNET_VERSION=v0.15.0
ENV JB_VERSION=v0.3.1
ENV PROTOC_GEN_SWAGGER_VERSION=v1.8.6
ENV GOCOVMERGE_VERSION=b5bfa59ec0adc420475f97f89b58045c721d761c
ENV BENCHSTAT_VERSION=9c9101da8316
ENV GH_VERSION=2.27.0
ENV K8S_TEST_INFRA_VERSION=2acdc6800510dd422bfd2a5d8c02aedc19d15f8d
ENV BUF_VERSION=v1.13.1
ENV GCLOUD_VERSION=425.0.0
ENV SU_EXEC_VERSION=0.2
ENV BAZEL_VERSION=6.0.0
ENV BOM_VERSION=v0.5.1
ENV CRANE_VERSION=v0.14.0
ENV YQ_VERSION=4.33.2
ENV FPM_VERSION=eb5370d16e361db3f1425f8c898bafe7f3c66869
ENV MDL_VERSION=0.12.0

ENV GOPROXY="https://proxy.golang.org,direct"
ENV GO111MODULE=on
ENV GOBIN=/usr/local/bin
ENV GOSUMDB=sum.golang.org
ENV GOPATH=/go
ENV GOCACHE=/gocache

ENV PATH=/usr/local/go/bin:/rust/bin:/usr/local/google-cloud-sdk/bin:$PATH

WORKDIR /root

# Install all dependencies available in RPM repos
# Stick with clang 13
# Stick with golang 1.20
RUN curl -sfL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    curl -sfL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf -y upgrade --refresh && \
    dnf -y install dnf-plugins-core && \
    dnf -y config-manager --set-enabled powertools && \
    dnf -y install epel-release epel-next-release && \
    dnf -y copr enable @maistra/istio-2.3 centos-stream-8-x86_64 && \
    dnf -y module reset ruby nodejs python38 && dnf -y module enable ruby:2.7 nodejs:16 python38 && dnf -y module install ruby nodejs python38 && \
    dnf -y install --setopt=install_weak_deps=False \
                   git make libtool patch which ninja-build go-toolset-0:1.20.4 xz redhat-rpm-config \
                   autoconf automake libtool cmake python2 libstdc++-static \
                   java-11-openjdk-devel jq file diffutils lbzip2 \
                   ruby-devel zlib-devel openssl-devel python2-setuptools gcc-toolset-12-libatomic-devel \
                   clang-0:13.0.0-3.module_el8.6.0+1074+380cef3f llvm-0:13.0.0-3.module_el8.6.0+1029+6594c364 lld-0:13.0.0-2.module_el8.6.0+1064+393664b9 compiler-rt-0:13.0.0-1.module_el8.6.0+1029+6594c364 \
                   binaryen emsdk docker-ce docker-buildx-plugin npm yarn rpm-build && \
    dnf -y clean all

# Build and install a bunch of Go tools
RUN go install -ldflags="-s -w" google.golang.org/protobuf/cmd/protoc-gen-go@${GOLANG_PROTOBUF_VERSION} && \
    go install -ldflags="-s -w" google.golang.org/grpc/cmd/protoc-gen-go-grpc@${GOLANG_GRPC_PROTOBUF_VERSION} && \
    go install -ldflags="-s -w" github.com/uber/prototool/cmd/prototool@${PROTOTOOL_VERSION} && \
    go install -ldflags="-s -w" github.com/nilslice/protolock/cmd/protolock@${PROTOLOCK_VERSION} && \
    go install -ldflags="-s -w" golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION} && \
    go install -ldflags="-s -w" github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION} && \
    go install -ldflags="-s -w" github.com/go-bindata/go-bindata/go-bindata@${GO_BINDATA_VERSION} && \
    go install -ldflags="-s -w" github.com/envoyproxy/protoc-gen-validate@${PROTOC_GEN_VALIDATE_VERSION} && \
    go install -ldflags="-s -w" github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@${PROTOC_GEN_GRPC_GATEWAY_VERSION} && \
    go install -ldflags="-s -w" github.com/google/go-jsonnet/cmd/jsonnet@${JSONNET_VERSION} && \
    go install -ldflags="-s -w" github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@${JB_VERSION} && \
    go install -ldflags="-s -w" github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@${PROTOC_GEN_SWAGGER_VERSION} && \
    go install -ldflags="-s -w" github.com/istio/go-junit-report@${GO_JUNIT_REPORT_VERSION} && \
    go install -ldflags="-s -w" sigs.k8s.io/bom/cmd/bom@${BOM_VERSION} && \
    go install -ldflags="-s -w" sigs.k8s.io/kind@${KIND_VERSION} && \
    go install -ldflags="-s -w" github.com/wadey/gocovmerge@${GOCOVMERGE_VERSION} && \
    go install -ldflags="-s -w" github.com/imsky/junit-merger/src/junit-merger@${JUNIT_MERGER_VERSION} && \
    go install -ldflags="-s -w" golang.org/x/perf/cmd/benchstat@${BENCHSTAT_VERSION} && \
    go install -ldflags="-s -w" github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION} && \
\
    go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-docs@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/annotations_prep@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/cue-gen@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-golang-deepcopy@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/protoc-gen-golang-jsonshim@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/kubetype-gen@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" istio.io/tools/cmd/gen-release-notes@${ISTIO_TOOLS_SHA} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/applyconfiguration-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/defaulter-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/client-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/lister-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/informer-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/deepcopy-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    go install -ldflags="-s -w" k8s.io/code-generator/cmd/go-to-protobuf@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    \
    # pr creator
    mkdir -p /root/test-infra && \
    cd /root/test-infra && \
    git init && \
    git remote add origin https://github.com/kubernetes/test-infra.git && \
    git fetch --depth 1 origin ${K8S_TEST_INFRA_VERSION} && \
    git checkout FETCH_HEAD && \
    go install ./robots/pr-creator && \
    go install ./prow/cmd/peribolos && \
    go install ./prow/cmd/checkconfig && \
    go install ./pkg/benchmarkjunit && \
    \
    rm -rf /root/* /root/.cache /tmp/* /gocache/* /go/pkg

# YQ
RUN curl -sfL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 -o /usr/local/bin/yq-go && chmod +x /usr/local/bin/yq-go

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

# ShellCheck linter
RUN curl -sfL https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJ shellcheck-${SHELLCHECK_VERSION}/shellcheck --strip=1 && \
    mv shellcheck /usr/bin/shellcheck

# Other lint tools
RUN curl -sfL https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 -o /usr/bin/hadolint && \
    chmod +x /usr/bin/hadolint

# Helm
RUN curl -sfL https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1 && \
    mv helm /usr/local/bin/helm && chown root.root /usr/local/bin/helm && ln -s /usr/local/bin/helm /usr/local/bin/helm3

# Kubectl
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Protoc
RUN curl -sfLO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    mv bin/protoc /usr/local/bin && \
    rm -rf /root/* /root/.cache /tmp/*

# Promu
RUN curl -sfLO https://github.com/prometheus/promu/releases/download/v${PROMU_VERSION}/promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    tar -zxvf promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    mv promu-${PROMU_VERSION}.linux-amd64/promu /usr/local/bin && chown root.root /usr/local/bin/promu && \
    rm -rf /root/* /root/.cache /tmp/*

# Google cloud tools
RUN curl -sfL -o /tmp/gc.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf /tmp/gc.tar.gz -C /usr/local && rm -f /tmp/gc.tar.gz

# Buf
RUN curl -sfL -o /usr/bin/buf https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-x86_64 && \
    chmod 555 /usr/bin/buf

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

# FPM
RUN mkdir -p /tmp/fpm && \
    cd /tmp/fpm && \
    git init && \ 
    git remote add origin https://github.com/jordansissel/fpm && \
    git fetch --depth 1 origin ${FPM_VERSION} && \
    git checkout FETCH_HEAD && \
    make install && \
    rm -rf /tmp/*

# MDL
RUN gem install --no-wrappers --no-document mdl -v ${MDL_VERSION} && \
    rm -rf /root/* /root/.cache /root/.gem /tmp/*

# Rust (for WASM filters)
ENV CARGO_HOME "/rust"
ENV RUSTUP_HOME "/rust"
RUN mkdir /rust && chmod 777 /rust && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    /rust/bin/rustup target add wasm32-unknown-unknown

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work

# Workarounds for proxy and bazel
RUN useradd user && chmod 777 /home/user
ENV USER=user HOME=/home/user
RUN ln -s /usr/bin/python3 /usr/bin/python && alternatives --set python3 /usr/bin/python3.8
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
