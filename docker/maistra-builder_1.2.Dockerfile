FROM fedora:31

# Versions

ENV KUBECTL_VERSION="v1.17.0"
ENV HELM_VERSION="v2.16.6"
ENV VALE_VERSION="v2.1.1"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN curl -sfL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    curl -sfL https://copr.fedorainfracloud.org/coprs/bavery/html-proofer/repo/fedora-31/bavery-html-proofer-fedora-31.repo -o /etc/yum.repos.d/html-proofer.repo && \
    dnf -y update && \
    dnf -y install fedpkg copr-cli jq xz unzip hostname golang \
                   make automake gcc gcc-c++ git ShellCheck which \
                   hugo rubygem-asciidoctor rubygem-html-proofer docker-ce && \
    dnf -y clean all


# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin github.com/jstemmer/go-junit-report && \
    gobin k8s.io/test-infra/robots/pr-creator && \
    rm -rf /root/* /root/.cache /tmp/*

# Helm
RUN curl https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -xz linux-amd64/helm --strip=1 && mv helm /usr/local/bin

# Kubectl
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Docs
RUN curl -sfL https://install.goreleaser.com/github.com/ValeLint/vale.sh -o ./vale.sh && \
    chmod +x ./vale.sh && ./vale.sh -b /usr/local/bin ${VALE_VERSION} && \
    rm -f ./vale.sh

ADD scripts/entrypoint.sh /usr/local/bin/entrypoint

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work
ENV HOME /work

VOLUME /var/lib/docker
ENTRYPOINT ["entrypoint"]
