FROM centos:8

ENV PATH /usr/local/go/bin:/go/bin:${PATH}

# Install dependencies
COPY scripts /tmp/scripts
WORKDIR /tmp/scripts
RUN chmod -R +x /tmp/scripts/ && \
    /tmp/scripts/install_base.sh && \
    /tmp/scripts/install_go_13.sh && \
    /tmp/scripts/install_helm.sh && \
    /tmp/scripts/install_shellcheck.sh && \
    /tmp/scripts/install_kubectl.sh && \
    /tmp/scripts/install_docker.sh && \
    /tmp/scripts/install_docs_tools.sh
    rm -rf /tmp/scripts

COPY scripts/runtime/ /tests/

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow

ADD scripts/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

RUN dnf clean all && dnf update -y

VOLUME /var/lib/docker
ENTRYPOINT ["entrypoint"]
