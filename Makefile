HUB ?= registry.gitlab.com/dgrimm/istio

BUILD_IMAGE = maistra-builder
BUILD_IMAGE_VERSIONS = $(BUILD_IMAGE)_1.1 ${BUILD_IMAGE}_1.0

${BUILD_IMAGE}: $(BUILD_IMAGE_VERSIONS)

${BUILD_IMAGE}_%:
	docker build -t ${HUB}/${BUILD_IMAGE}:$* \
				 -f docker/$@.Dockerfile docker

${BUILD_IMAGE}.push: ${BUILD_IMAGE}
	docker push ${HUB}/${BUILD_IMAGE}
