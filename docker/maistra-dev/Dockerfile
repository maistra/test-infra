FROM docker:stable as docker

FROM quay.io/maistra-dev/maistra-builder:2.4 as build-tools

FROM registry.access.redhat.com/ubi8/ubi:8.8-854
ARG user
ARG group
ARG uid=1000
ARG gid=1000

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=build-tools /usr/bin/hadolint /usr/bin/
COPY --from=build-tools /usr/local/bin/helm /usr/local/bin/
COPY --from=build-tools /usr/local/bin/kind /usr/local/bin/
COPY --from=build-tools /usr/local/bin/protoc /usr/local/bin/
COPY --from=build-tools /usr/bin/shellcheck /usr/bin/
COPY --from=build-tools /usr/local/bin/yq /usr/local/bin/
COPY --from=build-tools /go/ /usr/local/go/
COPY --from=build-tools /usr/local/ /usr/local/

# Install development packages.
RUN dnf -y upgrade --refresh && dnf -y install --setopt=install_weak_deps=False \
autoconf-0:2.69-29.el8 \
automake-0:1.16.1-7.el8 \
bash-completion-1:2.7-5.el8 \
llvm-toolset-0:15.0.7-1.module+el8.8.0+17939+b58878af \
ca-certificates-0:2022.2.54-80.2.el8_6  \
curl-0:7.61.1-30.el8_8.2 \
git-0:2.39.3-1.el8_8 \
iptables-0:1.8.4-24.el8 \
jq-0:1.6-6.el8 \
libtool-0:2.4.6-25.el8 \
make-1:4.2.1-11.el8 \
python38-0:3.8.16-1.module+el8.8.0+17624+9a09af5a \
sudo-0:1.8.29-10.el8 \
unzip-0:6.0-46.el8 \
vim-enhanced-2:8.0.1763-19.el8_6.4 \
wget-0:1.19.5-11.el8 \
xz-0:5.2.4-4.el8_6 \
&& dnf -y clean all

# Create user and allow sudo without password.
RUN groupadd --gid $gid $group \
&& adduser --uid $uid --gid $group $user \
&& echo "${user} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$user

# Install Docker CLI.
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker

# Install kubectl.
ENV KUBECTL_VERSION=1.25.3
RUN curl -sfL https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install bash completion files.
RUN /usr/local/bin/kind completion bash > /etc/bash_completion.d/kind \
&& /usr/local/bin/helm completion bash > /etc/bash_completion.d/helm \
&& /usr/local/bin/kubectl completion bash > /etc/bash_completion.d/kubectl \
&& curl -s -Lo - https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker > /etc/bash_completion.d/docker

USER $user

# Fix the Docker socket access rights at login time to allow non-root access.
RUN echo "sudo chmod o+rw /var/run/docker.sock" >> /home/${user}/.bashrc

# Setup Go for the user.
RUN echo "# Go environment." >> /home/${user}/.bashrc \
&& echo "export GOROOT=/usr/local/go" >> /home/${user}/.bashrc \
&& echo "export GOPATH=~/go" >> /home/${user}/.bashrc \
&& echo "export PATH=\$GOROOT/bin:\$GOPATH/out/linux_amd64/release:\$GOPATH/bin:\$PATH" >> /home/${user}/.bashrc \
&& echo "export GO111MODULE=on" >> /home/${user}/.bashrc

WORKDIR /home/$user
ENTRYPOINT ["/bin/bash", "-c"]
