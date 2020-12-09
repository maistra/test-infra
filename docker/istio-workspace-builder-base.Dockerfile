FROM fedora:33

ENV OC_VERSION="4.6.3"

ENV GOPROXY="https://proxy.golang.org,direct"

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

# Install all dependencies available in RPM repos
RUN dnf -y update && \
#    dnf -y install https://download-ib01.fedoraproject.org/pub/fedora/linux/updates/$(rpm -E %fedora)/Everything/x86_64/Packages/c/containers-common-1.2.0-10.fc$(rpm -E %fedora).x86_64.rpm && \
    dnf -y install bash-completion jq xz golang-1.15.5 ruby make wget which inotify-tools podman buildah && \
#    dnf -y update --refresh --enablerepo=updates-testing podman buildah && \
    dnf -y clean all

# Go tools
ENV GOBIN=/usr/local/bin

# Enable image builds on k8s/openshift cluster
RUN printf '[engine]\ncgroup_manager="cgroupfs"\n' > /etc/containers/containers.conf

VOLUME /var/lib/docker

RUN mkdir -p /status && chmod 777 /status
