HUB ?= quay.io/maistra-dev
CONTAINER_CLI ?= docker

BUILD_IMAGE = maistra-builder
BUILD_IMAGE_VERSIONS = $(BUILD_IMAGE)_3.0 $(BUILD_IMAGE)_2.6 $(BUILD_IMAGE)_2.5 $(BUILD_IMAGE)_2.4 $(BUILD_IMAGE)_2.3 $(BUILD_IMAGE)_2.2

${BUILD_IMAGE}: $(BUILD_IMAGE_VERSIONS)

# Build a specific maistra image. Example of usage: make maistra-builder_2.3
${BUILD_IMAGE}_%:
	$(CONTAINER_CLI) build -t ${HUB}/${BUILD_IMAGE}:$* \
				 -f docker/$@.Dockerfile docker

# Build a specific arm64 maistra image. Example of usage: make maistra-builder_2.4_arm64
${BUILD_IMAGE}_%_arm64:
	$(CONTAINER_CLI) build -t ${HUB}/${BUILD_IMAGE}:$* \
				 --build-arg TARGETARCH=arm64 \
				 -f docker/$@.Dockerfile docker

# Build and push all maistra images. Example of usage: make maistra-builder.push
${BUILD_IMAGE}.push: ${BUILD_IMAGE}
	$(CONTAINER_CLI) push --all-tags ${HUB}/${BUILD_IMAGE}

# Build and push a specific maistra image. Example of usage: make maistra-builder_2.3.push
${BUILD_IMAGE}_%.push: ${BUILD_IMAGE}_%
	$(CONTAINER_CLI) push ${HUB}/${BUILD_IMAGE}:$*

lint:
	find . -name '*.sh' -print0 | xargs -0 -r shellcheck

# these will build the containers and then try to use them to build themselves again, making sure we didn't break docker support
build-containers-%: ${BUILD_IMAGE}_%
	$(CONTAINER_CLI) run --privileged -v ${PWD}:/work --workdir /work -v /var/lib/docker --entrypoint entrypoint ${HUB}/maistra-builder:$* make maistra-builder_$*
