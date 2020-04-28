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
