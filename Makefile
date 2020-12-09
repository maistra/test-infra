HUB ?= quay.io/maistra
BUILD_IMAGE_PREFIX = istio-workspace
BUILD_IMAGE_TAG ?= latest
BUILD_IMAGES = $(BUILD_IMAGE_PREFIX)-builder-base $(BUILD_IMAGE_PREFIX)-image-builder $(BUILD_IMAGE_PREFIX)-tester

images: $(BUILD_IMAGES)

${BUILD_IMAGE_PREFIX}-%:
	$(eval IMAGE := ${BUILD_IMAGE_PREFIX}-$*:${BUILD_IMAGE_TAG})

	docker build -t ${HUB}/${IMAGE} \
				 -f docker/$@.Dockerfile docker
	docker push ${HUB}/${IMAGE}

gen-check: gen check-clean-repo

gen:
	(cd prow; sh gen-config.sh)

check-clean-repo:
	@if [[ -n $$(git status --porcelain) ]]; then git status; git diff; echo "ERROR: Some files need to be updated, please run 'make gen' and include any changed files in your PR"; exit 1;	fi

update-prow:
	(cd prow; sh update.sh)

