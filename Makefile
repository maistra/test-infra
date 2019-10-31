HUB ?= docker.io/dgrimm
IMAGE ?= maistra-builder
TAG ?= latest

builder-image:
	docker build -t ${HUB}/${IMAGE}:${TAG} \
				 -t ${HUB}/${IMAGE}:latest \
				 -f docker/maistra-builder.Dockerfile docker
