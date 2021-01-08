FROM registry.access.redhat.com/ubi8/nodejs-14:latest

USER 1000

RUN npm install smee-client

ENTRYPOINT smee -u $SMEE_SOURCE -t $SMEE_TARGET
