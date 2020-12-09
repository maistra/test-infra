FROM quay.io/maistra/istio-workspace-builder-base:latest

# Kubectl / oc
RUN wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz" -O "oc.tar.gz" && \
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

ADD scripts/istio-workspace-e2e.sh /usr/local/bin/run-tests.sh
RUN chmod +x /usr/local/bin/run-tests.sh
