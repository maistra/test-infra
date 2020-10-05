FROM fedora:31

# Versions
ENV GO_VERSION="1.14.4"
ENV KUBECTL_VERSION="v1.17.0"
ENV HELM_VERSION="v2.16.6"
ENV VALE_VERSION="v2.1.1"
ENV KIND_VERSION="v0.7.0"

#this needs to match the version of Hugo used in maistra.io's netlify.toml file
ENV HUGO_VERSION="0.69.2"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN curl -sfL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    curl -sfL https://copr.fedorainfracloud.org/coprs/bavery/html-proofer/repo/fedora-31/bavery-html-proofer-fedora-31.repo -o /etc/yum.repos.d/html-proofer.repo && \
    dnf -y update && \
    dnf -y install fedpkg copr-cli jq xz unzip hostname \
                   make automake gcc gcc-c++ git ShellCheck which \
                   rubygem-asciidoctor rubygem-html-proofer docker-ce \
                   npm && \
    dnf -y clean all


# Go
RUN curl https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | tar -xz -C /usr/local
ENV PATH=${PATH}:/usr/local/go/bin

# Go tools
ENV GOBIN=/usr/local/bin
RUN GO111MODULE=off go get github.com/myitcv/gobin && \
    gobin github.com/jstemmer/go-junit-report && \
    gobin k8s.io/test-infra/robots/pr-creator@41512c7491a99c6bdf330e1a76d45c8a10d3679b && \
    gobin k8s.io/test-infra/prow/cmd/checkconfig@41512c7491a99c6bdf330e1a76d45c8a10d3679b && \
    gobin github.com/mikefarah/yq/v3 && \
    rm -rf /root/* /root/.cache /tmp/*

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

# gcloud
# some upstream scripts rely on gcloud commands to retrieve credentials for
# e.g. pushing to GCS buckets. We don't require this at this point, so we're
# only creating a stub script to make sure scripts don't fail because gcloud
# is missing.
RUN echo 'echo "gcloud is not installed. Skipping"' > /usr/local/bin/gcloud && \
    chmod +x /usr/local/bin/gcloud

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

