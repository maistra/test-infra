FROM registry.access.redhat.com/ubi8:8.0

ENV PATH /usr/local/go/bin:/go/bin:${PATH}

# Install dependencies
COPY scripts /tmp/scripts
WORKDIR /tmp/scripts
RUN chmod -R +x /tmp/scripts/ 
RUN /tmp/scripts/install/install_base.sh
RUN /tmp/scripts/install/install_go_12.sh
RUN /tmp/scripts/install/install_helm.sh
RUN /tmp/scripts/install/install_shellcheck.sh

RUN rm -rf /tmp/scripts

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow
