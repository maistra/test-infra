# Hack: Remove this once the base image has go 1.16
FROM golang:1.16 AS go116

ENV K8S_TEST_INFRA_VERSION=5b1d25764f
RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
    cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
    go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
    go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go

FROM fedora:33

# Versions
ENV ISTIO_TOOLS_SHA=f4cf625fd815a0300e5ca541d03bc57057dad289
ENV KUBECTL_VERSION="v1.20.0"
ENV HELM3_VERSION=v3.1.2
ENV VALE_VERSION="v2.1.1"
ENV KIND_VERSION="v0.9.0"
ENV AUTOPEP8_VERSION=1.4.4
ENV GOLANGCI_LINT_VERSION=v1.30.0
ENV HADOLINT_VERSION=v1.17.2
ENV MDL_VERSION=0.5.0
ENV YAMLLINT_VERSION=1.17.0
ENV HTML_PROOFER=3.15.3
ENV GO_BINDATA_VERSION=v3.1.2
ENV COUNTERFEITER_VERSION=v6.2.3
ENV PROTOC_VERSION=3.9.2
ENV GOIMPORTS_VERSION=379209517ffe
ENV GOGO_PROTOBUF_VERSION=v1.3.2
ENV GO_JUNIT_REPORT_VERSION=af01ea7f8024089b458d804d5cdf190f962a9a0c
ENV K8S_CODE_GENERATOR_VERSION=1.18.1
ENV LICENSEE_VERSION=9.11.0
ENV GOLANG_PROTOBUF_VERSION=v1.3.2
ENV FPM_VERSION=1.11.0
ENV SHELLCHECK_VERSION=v0.7.1
ENV PROMU_VERSION=0.7.0

#this needs to match the version of Hugo used in maistra.io's netlify.toml file
ENV HUGO_VERSION="0.69.2"

ENV GOPROXY="https://proxy.golang.org,direct"

# Install all dependencies available in RPM repos
RUN curl -sfL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    dnf -y update && \
    dnf -y install fedpkg copr-cli jq xz unzip hostname golang \
                   make automake gcc gcc-c++ git which \
                   docker-ce npm python3-pip rubygems cmake \
                   rubygem-asciidoctor ruby-devel zlib-devel \
                   openssl-devel && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin github.com/jstemmer/go-junit-report@${GO_JUNIT_REPORT_VERSION} && \
    gobin github.com/mikefarah/yq/v3 && \
    gobin github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION} && \
    gobin github.com/go-bindata/go-bindata/go-bindata@${GO_BINDATA_VERSION} && \
    gobin github.com/maxbrunsfeld/counterfeiter/v6@${COUNTERFEITER_VERSION} && \
    gobin golang.org/x/tools/cmd/goimports@${GOIMPORTS_VERSION} && \
    gobin github.com/gogo/protobuf/protoc-gen-gogoslick@${GOGO_PROTOBUF_VERSION} && \
    gobin github.com/golang/protobuf/protoc-gen-go@${GOLANG_PROTOBUF_VERSION} && \
    gobin github.com/gogo/protobuf/protoc-gen-gofast@${GOGO_PROTOBUF_VERSION} && \
    gobin github.com/gogo/protobuf/protoc-gen-gogofast@${GOGO_PROTOBUF_VERSION} && \
    gobin github.com/gogo/protobuf/protoc-gen-gogofaster@${GOGO_PROTOBUF_VERSION} && \
    gobin github.com/gogo/protobuf/protoc-gen-gogoslick@${GOGO_PROTOBUF_VERSION}  && \
    mv /usr/local/bin/yq /usr/local/bin/yq-go && \
    rm -rf /root/* /root/.cache /tmp/*

# Install latest version of Istio-owned tools in this release
RUN gobin istio.io/tools/cmd/protoc-gen-docs@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/annotations_prep@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/cue-gen@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/protoc-gen-deepcopy@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/protoc-gen-jsonshim@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/kubetype-gen@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/gen-release-notes@${ISTIO_TOOLS_SHA}

# Hack: Revert this once the base image has go 1.16
# RUN git clone https://github.com/kubernetes/test-infra.git /root/test-infra && \
#     cd /root/test-infra && git checkout ${K8S_TEST_INFRA_VERSION} && \
#     go build -o /usr/local/bin/checkconfig prow/cmd/checkconfig/main.go && \
#     go build -o /usr/local/bin/pr-creator robots/pr-creator/main.go && \
#     rm -rf /root/* /root/.cache /tmp/*
COPY --from=go116 /usr/local/bin/pr-creator /usr/local/bin/pr-creator
COPY --from=go116 /usr/local/bin/checkconfig /usr/local/bin/checkconfig

# gobin does not seem to be compatible with this pesky code-generator repo
# Install the code generator tools, and hopefully only these tools, this way
RUN GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/defaulter-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/client-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/lister-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/informer-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/deepcopy-gen@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    GO111MODULE=on go get -ldflags="-s -w" k8s.io/code-generator/cmd/go-to-protobuf@kubernetes-${K8S_CODE_GENERATOR_VERSION} && \
    rm -rf /root/* /root/.cache /tmp/*

# Python tools
RUN pip3 install --no-binary :all: autopep8==${AUTOPEP8_VERSION} && \
    pip3 install yamllint==${YAMLLINT_VERSION} && \
    pip3 install yq && mv /usr/local/bin/yq /usr/local/bin/yq-python

# Default yq to yq-go
RUN ln -s /usr/local/bin/yq-go /usr/local/bin/yq

# Ruby tools
RUN gem install --no-wrappers --no-document mdl -v ${MDL_VERSION} && \
    gem install --no-wrappers --no-document html-proofer -v ${HTML_PROOFER} && \
    gem install --no-wrappers --no-document licensee -v ${LICENSEE_VERSION} && \
    gem install --no-document fpm -v ${FPM_VERSION}

# ShellCheck linter
RUN curl -sfL https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz | tar -xJ shellcheck-${SHELLCHECK_VERSION}/shellcheck --strip=1 && \
    mv shellcheck /usr/bin/shellcheck

# Other lint tools
RUN curl -sfL https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 -o /usr/bin/hadolint && \
    chmod +x /usr/bin/hadolint

# Helm
RUN curl -sfL https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1 && mv helm /usr/local/bin/helm && cp /usr/local/bin/helm /usr/local/bin/helm3

# Hugo
RUN curl -sfL https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz | tar -xz hugo && mv hugo /usr/local/bin

# Kubectl
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# KinD
RUN curl -Lo /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64 && \
    chmod +x /usr/local/bin/kind

# Docs
#FIXME: Vale is not working
# RUN curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o ./vale.sh && \
#     chmod +x ./vale.sh && ./vale.sh -b /usr/local/bin ${VALE_VERSION} && \
#     rm -f ./vale.sh

# Protoc
RUN curl -sfLO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    mv bin/protoc /usr/local/bin && \
    rm -rf /root/*

# Yarn
RUN npm install --global yarn

# Promu
RUN curl -sfLO https://github.com/prometheus/promu/releases/download/v${PROMU_VERSION}/promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    tar -zxvf promu-${PROMU_VERSION}.linux-amd64.tar.gz && \
    mv promu-${PROMU_VERSION}.linux-amd64/promu /usr/local/bin  && \
    rm -rf /root/*

# Rust (for WASM filters)
ENV CARGO_HOME "/rust"
ENV RUSTUP_HOME "/rust"
ENV PATH "${PATH}:/rust/bin"
RUN mkdir /rust && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    rustup target add wasm32-unknown-unknown

# OpenShift tools
RUN curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.7/openshift-install-linux.tar.gz | tar -xz openshift-install && mv openshift-install /usr/local/bin/openshift-install-4.7
RUN curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.8/openshift-install-linux.tar.gz | tar -xz openshift-install && mv openshift-install /usr/local/bin/openshift-install-4.8
RUN curl -sfL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.8/openshift-client-linux.tar.gz | tar -xz oc && mv oc /usr/local/bin

ADD scripts/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work
ENV HOME /work

VOLUME /var/lib/docker
ENTRYPOINT ["entrypoint"]
