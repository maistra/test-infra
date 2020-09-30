#!/bin/bash

set -ex

# re-generate config
echo "#======================================
# This configuration is auto-generated. 
# To update:
#    Modify files in the config directory
#    Run gen-config.sh to regenerate.
#======================================" > config.gen.yaml

for file in config/*; do
  cat "${file}" >> config.gen.yaml
done

BUILDER_IMAGE_NAME="quay.io\/maistra-dev\/maistra\-builder"
BUILDER_IMAGE_1_0="1.0"
BUILDER_IMAGE_1_1="1.1"
BUILDER_IMAGE_2_0="2.0"
PROXY_BUILDER_IMAGE_NAME="quay.io\/maistra-dev\/maistra\-proxy\-builder"
PROXY_BUILDER_IMAGE_1_1="1.1"
PROXY_BUILDER_IMAGE_2_0="2.0"

sed -i -e "s/\(${BUILDER_IMAGE_NAME}\):1\.0/\1:${BUILDER_IMAGE_1_0}/" config.gen.yaml
sed -i -e "s/\(${BUILDER_IMAGE_NAME}\):1\.1/\1:${BUILDER_IMAGE_1_1}/" config.gen.yaml
sed -i -e "s/\(${BUILDER_IMAGE_NAME}\):2\.0/\1:${BUILDER_IMAGE_2_0}/" config.gen.yaml
sed -i -e "s/\(${PROXY_BUILDER_IMAGE_NAME}\):1\.1/\1:${PROXY_BUILDER_IMAGE_1_1}/" config.gen.yaml
sed -i -e "s/\(${PROXY_BUILDER_IMAGE_NAME}\):2\.0/\1:${PROXY_BUILDER_IMAGE_2_0}/" config.gen.yaml
