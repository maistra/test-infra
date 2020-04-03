#!/bin/bash

set -ex

# re-generate config
rm config.gen.yaml
echo "#======================================
# This configuration is auto-generated. 
# To update:
#    Modify files in the config directory
#    Run gen-config.sh to regenerate.
#======================================" >> config.gen.yaml
for file in `ls config`; do
  cat config/$file >> config.gen.yaml
done
