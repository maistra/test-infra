FROM fedora:33  

ENV OC_VERSION="4.6.3"

ENV GOPROXY="https://proxy.golang.org,direct"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN dnf -y update && \
    dnf -y install bash-completion jq xz golang ruby make wget which buildah && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin

# Kubectl
RUN wget "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz" -O "oc.tar.gz" && \
    tar xzfv oc.tar.gz && \
    mv oc /usr/local/bin/ && \
    chmod +x /usr/local/bin/oc && \
    mv kubectl /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubectl && \
    rm oc.tar.gz && rm README.md

# Telepresence
RUN curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.rpm.sh | os=fedora dist=32 bash && \
    dnf -y install telepresence && \
    dnf -y clean all && \
    ln -s /usr/bin/fusermount3 /usr/bin/fusermount

ADD scripts/istio-workspace.sh /usr/local/bin/run-test.sh
RUN chmod +x /usr/local/bin/run-test.sh

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work
ENV HOME /work
ADD scripts/ike-builder-gitconfig /work/.gitconfig

VOLUME /var/lib/docker
