HUB ?= quay.io/maistra-dev
CONTAINER_CLI ?= docker

BUILD_IMAGE = maistra-builder
BUILD_IMAGE_VERSIONS = $(BUILD_IMAGE)_3.1 $(BUILD_IMAGE)_3.0 $(BUILD_IMAGE)_2.6 $(BUILD_IMAGE)_2.5 $(BUILD_IMAGE)_2.4 $(BUILD_IMAGE)_2.3 $(BUILD_IMAGE)_2.2

${BUILD_IMAGE}: $(BUILD_IMAGE_VERSIONS)

# BUILDX_OUTPUT defines the buildx output
# --load builds locally the container image. Load only can be used when is not multi-platform
# --push builds and pushes the container image to a registry
BUILDX_OUTPUT ?= 

ifneq ($(strip $(BUILDX_OUTPUT)),)
BUILDX_OUTPUT_FLAG := $(BUILDX_OUTPUT)
else
BUILDX_OUTPUT_FLAG :=
endif

# Supported platforms for the builder image
PLATFORMS ?= linux/arm64,linux/amd64

TARGET_OS ?= linux

# BUILDX_BUILD_ARGS are the additional --build-arg flags passed to the docker buildx build command.
BUILDX_BUILD_ARGS = --build-arg TARGETOS=$(TARGET_OS) --build-arg BUILDKIT_PARALLEL_LIMIT=1 --progress=plain

# Build a specific maistra image. Example of usage: make maistra-builder_2.3
# Only build single arch image by using the build command
${BUILD_IMAGE}_%:
	@echo "Building single-platform image with $(CONTAINER_CLI)" && \
	$(CONTAINER_CLI) build -t ${HUB}/${BUILD_IMAGE}:$* -f docker/$@.Dockerfile docker

# Build a maistra version for the platforms described in the PLATFORMS var. 
# Example of usage: make maistra-builder_2.5_multi
# This target is supported on >= 2.5 versions
${BUILD_IMAGE}_%_multi:
	@if [ "$(CONTAINER_CLI)" = "podman" ]; then \
		echo "Building multi-platform image with podman" && \
		$(CONTAINER_CLI) manifest create ${HUB}/${BUILD_IMAGE}:$* && \
		$(CONTAINER_CLI) build --platform $(PLATFORMS) --manifest ${HUB}/${BUILD_IMAGE}:$* -f docker/$(@:%_multi=%).Dockerfile docker; \
	else \
		echo "Building multi-platform image with docker buildx" && \
		$(CONTAINER_CLI) buildx create --name project-v4-builder && \
		$(CONTAINER_CLI) buildx use project-v4-builder && \
		$(CONTAINER_CLI) buildx build $(BUILDX_OUTPUT_FLAG) --platform=$(PLATFORMS) --tag ${HUB}/${BUILD_IMAGE}:$* $(BUILDX_BUILD_ARGS) -f docker/$(@:%_multi=%).Dockerfile docker && \
		$(CONTAINER_CLI) buildx rm project-v4-builder ;\
	fi

# Build and push all maistra images. Example of usage: make maistra-builder.push
${BUILD_IMAGE}.push: ${BUILD_IMAGE}
	@$(CONTAINER_CLI) push --all-tags ${HUB}/${BUILD_IMAGE}

# Build and push a specific single arch maistra image. Example of usage: make maistra-builder_2.3.push
${BUILD_IMAGE}_%.push:
	@echo "Building and pushing single-platform image" && \
	$(MAKE) ${BUILD_IMAGE}_$* && \
	$(CONTAINER_CLI) push ${HUB}/${BUILD_IMAGE}:$*

# Build and push multi image. Example of usage: make maistra-builder_2.5.push_multi
${BUILD_IMAGE}_%.push_multi:
	@echo "Building and pushing multi-platform image" && \
	if [ "$(CONTAINER_CLI)" = "podman" ]; then \
		$(MAKE) ${BUILD_IMAGE}_$*_multi && \
		$(CONTAINER_CLI) manifest push ${HUB}/${BUILD_IMAGE}:$*; \
	else \
		BUILDX_OUTPUT="--push" $(MAKE) ${BUILD_IMAGE}_$*_multi; \
	fi \


lint:
	find . -name '*.sh' -print0 | xargs -0 -r shellcheck

# these will build the containers and then try to use them to build themselves again, making sure we didn't break docker support
build-containers-%: ${BUILD_IMAGE}_%
	$(CONTAINER_CLI) run --privileged -v ${PWD}:/work --workdir /work -v /var/lib/docker --entrypoint entrypoint ${HUB}/maistra-builder:$* make maistra-builder_$*
