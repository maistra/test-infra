FROM registry.access.redhat.com/ubi8:8.0

ENV PATH /usr/local/go/bin:/go/bin:${PATH}

# Install dependencies
COPY scripts /tmp/scripts
WORKDIR /tmp/scripts
RUN chmod -R +x /tmp/scripts/ && /tmp/scripts/install_all.sh && rm -rf /tmp/scripts

# Set CI variable which can be checked by test scripts to verify
# if running in the continuous integration environment.
ENV CI prow
