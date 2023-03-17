HUB ?= quay.io/maistra-dev
CONTAINER_CLI ?= docker

BUILD_IMAGE = maistra-builder
BUILD_IMAGE_VERSIONS = $(BUILD_IMAGE)_3.0 $(BUILD_IMAGE)_2.4 $(BUILD_IMAGE)_2.3 $(BUILD_IMAGE)_2.2 $(BUILD_IMAGE)_2.1

${BUILD_IMAGE}: $(BUILD_IMAGE_VERSIONS)

# Build a specific maistra image. Example of usage: make maistra-builder_2.3
${BUILD_IMAGE}_%:
	$(CONTAINER_CLI) build -t ${HUB}/${BUILD_IMAGE}:$* \
				 -f docker/$@.Dockerfile docker

# Build and push all maistra images. Example of usage: make maistra-builder.push
${BUILD_IMAGE}.push: ${BUILD_IMAGE}
	$(CONTAINER_CLI) push --all-tags ${HUB}/${BUILD_IMAGE}

# Build and push a specific maistra image. Example of usage: make maistra-builder_2.3.push
${BUILD_IMAGE}_%.push: ${BUILD_IMAGE}_%
	$(CONTAINER_CLI) push ${HUB}/${BUILD_IMAGE}:$*

BUILD_PROXY_IMAGE = maistra-proxy-builder
BUILD_PROXY_IMAGE_VERSIONS = $(BUILD_PROXY_IMAGE)_2.1

${BUILD_PROXY_IMAGE}: $(BUILD_PROXY_IMAGE_VERSIONS)

# Build a specific proxy image. Example of usage: make maistra-proxy-builder_2.1
${BUILD_PROXY_IMAGE}_%:
	$(CONTAINER_CLI) build -t ${HUB}/${BUILD_PROXY_IMAGE}:$* \
				 -f docker/$@.Dockerfile docker

# Build and push all proxy images. Example of usage: make maistra-proxy-builder.push
${BUILD_PROXY_IMAGE}.push: ${BUILD_PROXY_IMAGE}
	$(CONTAINER_CLI) push --all-tags ${HUB}/${BUILD_PROXY_IMAGE}

# Build and push a specific proxy image. Example of usage: make maistra-proxy-builder_2.1.push
${BUILD_PROXY_IMAGE}_%.push: ${BUILD_PROXY_IMAGE}_%
	$(CONTAINER_CLI) push ${HUB}/${BUILD_PROXY_IMAGE}:$*

gen-check: gen check-clean-repo

gen:
	(cd prow; sh gen-config.sh)

check-clean-repo:
	@if [[ -n $$(git status --porcelain) ]]; then git status; git diff; echo "ERROR: Some files need to be updated, please run 'make gen' and include any changed files in your PR"; exit 1;	fi

update-prow:
	(cd prow; sh update.sh)

lint:
	find . -name '*.sh' -print0 | xargs -0 -r shellcheck
	checkconfig -strict -config-path prow/config.gen.yaml -plugin-config prow/plugins.yaml
	@scripts/check-resource-limits.sh

# these will build the containers and then try to use them to build themselves again, making sure we didn't break docker support
build-containers-%: ${BUILD_IMAGE}_%
	$(CONTAINER_CLI) run --privileged -v ${PWD}:/work --workdir /work -v /var/lib/docker --entrypoint entrypoint ${HUB}/maistra-builder:$* make maistra-builder_$*
