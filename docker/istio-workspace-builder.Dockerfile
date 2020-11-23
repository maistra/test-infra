FROM fedora:33  

# Versions
ENV OC_VERSION="4.5.5"

ENV GOPROXY="https://proxy.golang.org,direct"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN dnf -y update && \
    dnf -y install jq xz golang make wget which buildah && \
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

ADD scripts/istio-workspace.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN mkdir -p /work && chmod 777 /work
WORKDIR /work
ENV HOME /work

VOLUME /var/lib/docker
ENTRYPOINT ["entrypoint"]
