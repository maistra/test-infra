#!/bin/bash

set -ex

# re-generate config
rm config.gen.yaml
for file in `ls config`; do
  cat config/$file >> config.gen.yaml
done
