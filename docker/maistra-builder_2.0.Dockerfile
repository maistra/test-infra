FROM fedora:32

# Versions
ENV ISTIO_TOOLS_SHA=3a83f1998fbac342979d7fd0b6100c15e4931e9f
ENV KUBECTL_VERSION="v1.17.0"
ENV HELM_VERSION="v2.16.6"
ENV VALE_VERSION="v2.1.1"
ENV KIND_VERSION="v0.7.0"
ENV AUTOPEP8_VERSION=1.4.4
ENV GOLANGCI_LINT_VERSION=v1.24.0
ENV HADOLINT_VERSION=v1.17.2
ENV MDL_VERSION=0.5.0
ENV YAMLLINT_VERSION=1.17.0
ENV HTML_PROOFER=3.15.3

#this needs to match the version of Hugo used in maistra.io's netlify.toml file
ENV HUGO_VERSION="0.69.2"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN dnf -y update && \
    dnf -y install fedpkg copr-cli jq xz unzip hostname golang \
                   make automake gcc gcc-c++ git ShellCheck which \
                   moby-engine npm python3-pip rubygems \
                   rubygem-asciidoctor ruby-devel zlib-devel && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin github.com/jstemmer/go-junit-report && \
    gobin k8s.io/test-infra/robots/pr-creator@41512c7491a99c6bdf330e1a76d45c8a10d3679b && \
    gobin k8s.io/test-infra/prow/cmd/checkconfig@41512c7491a99c6bdf330e1a76d45c8a10d3679b && \
    gobin github.com/mikefarah/yq/v3 && \
    gobin github.com/golangci/golangci-lint/cmd/golangci-lint@${GOLANGCI_LINT_VERSION} && \
    gobin istio.io/tools/cmd/license-lint@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/testlinter@${ISTIO_TOOLS_SHA} && \
    gobin istio.io/tools/cmd/envvarlinter@${ISTIO_TOOLS_SHA} && \
    rm -rf /root/* /root/.cache /tmp/*

# Python tools
RUN pip3 install --no-binary :all: autopep8==${AUTOPEP8_VERSION} && \
    pip3 install yamllint==${YAMLLINT_VERSION}

# Ruby tools
RUN gem install --no-wrappers --no-document mdl -v ${MDL_VERSION} && \
    gem install --no-wrappers --no-document html-proofer -v ${HTML_PROOFER}

# Other lint tools
RUN curl -sfL https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 -o /usr/bin/hadolint && \
    chmod +x /usr/bin/hadolint

# Helm
RUN curl https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1 && mv helm /usr/local/bin

# Hugo
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz | tar -xz hugo && mv hugo /usr/local/bin

# Kubectl
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# KinD
RUN curl -Lo /usr/local/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64 && \
    chmod +x /usr/local/bin/kind

# Docs
RUN curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o ./vale.sh && \
    chmod +x ./vale.sh && ./vale.sh -b /usr/local/bin ${VALE_VERSION} && \
    rm -f ./vale.sh

ADD scripts/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work
ENV HOME /work

VOLUME /var/lib/docker
ENTRYPOINT ["entrypoint"]
