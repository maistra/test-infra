HUB ?= quay.io/maistra-dev

BUILD_IMAGE = maistra-builder
BUILD_IMAGE_VERSIONS = $(BUILD_IMAGE)_1.2 $(BUILD_IMAGE)_1.1 ${BUILD_IMAGE}_1.0

${BUILD_IMAGE}: $(BUILD_IMAGE_VERSIONS)

${BUILD_IMAGE}_%:
	docker build -t ${HUB}/${BUILD_IMAGE}:$* \
				 -f docker/$@.Dockerfile docker

${BUILD_IMAGE}.push: ${BUILD_IMAGE}
	docker push ${HUB}/${BUILD_IMAGE}

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

# this will build the containers and then try to use them to build themselves again, making sure we didn't break docker support
build-containers: maistra-builder
	docker run --privileged -v ${PWD}:/work --workdir /work ${HUB}/maistra-builder:1.1 make maistra-builder
	docker run --privileged -v ${PWD}:/work --workdir /work ${HUB}/maistra-builder:1.2 make maistra-builder
