FROM fedora:33

ENV OC_VERSION="4.6.3"

ENV GOPROXY="https://proxy.golang.org,direct"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN dnf -y update && \
    dnf -y install bash-completion jq xz golang ruby make wget which inotify-tools podman buildah && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin

# Enable image builds on k8s/openshift cluster
RUN printf '[engine]\ncgroup_manager="cgroupfs"\n' > /etc/containers/containers.conf

VOLUME /var/lib/docker

RUN mkdir -p /status && chmod 777 /status
