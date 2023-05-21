# Builder images

This directory contains the source (Dockerfiles) of the container images used to run the jobs in prow.

There is one container image (therefore one Dockerfile) for every supported branch in the Maistra project. For example, jobs in the `maistra-2.2` branch use the `maistra-builder:2.2` container image, which source code is in the [maistra-builder_2.2.Dockerfile](maistra-builder_2.2.Dockerfile).


> Note: Before the version `2.2`, there were two container images (therefore two Dockerfiles) for each branch, one named `maistra-builder` and the other one named `maistra-proxy-builder`. Starting with `2.2` those two images were unified into a single `maistra-builder` image.

These images run the jobs configured in prow.

## Rationale

These images are based on the Istio and Envoy version that a Maistra branch targets. For example, the branch `maistra-2.2` in Maistra repositories (e.g., maistra/istio, maistra/proxy, etc) targets Istio `1.12` and Envoy `1.20`. Thus the Dockerfile for `2.2` (`maistra-builder_2.2.Dockerfile`) contains all the tooling necessary to build Istio `1.12` and Envoy `1.20`.

This is usually done by keeping the tools - and its versions - aligned to those used in the [Istio builder image](https://github.com/istio/tools/blob/master/docker/build-tools/Dockerfile). So, when creating a new Maistra container image (for a newer Maistra branch), look at this Dockerfile from Istio, making sure to look at the right branch that we are targeting, not `master`.

## Testing locally

When developing a new builder image, it's a good practice to test it locally to make sure it builds correctly from the Dockerfile, and that it is able to actually run the jobs.

To build the `maistra-builder` container image locally, run `make maistra-builder` in this repository, in the main directory. It will build all available versions of the container; generally, one per maistra minor version: 2.3, 2.4, etc. If you want to build only one specific version, append `_VERSION` to the make target, e.g.: `make maistra_builder_2.4`. Take a kook at the [Makefile](../Makefile) for other targets.


## Workflow

These are the steps when developing a container image for a newer Maistra version. For the sake of this example, let's assume you are building for **Maistra `3.3`**, based on **Istio `2.2`**.

1. Duplicate the latest `maistra-builder` Dockerfile, naming it `maistra-builder_3.3.Dockerfile`.
1. Look at the [corresponding Dockerfile from Istio, branch 2.2](https://github.com/istio/tools/blob/release-2.2/docker/build-tools/Dockerfile) and make the necessary adjustments, e.g. using the same tools and version numbers.
1. Look at the tooling necessary to build Envoy & Proxy. For bazel version, look at the [`.bazelversion`](https://github.com/istio/proxy/blob/release-2.2/.bazelversion) file (again, make sure to look at the right, target branch). Other tooling (like gcc/clang versions) don't change too often, but still it's worth checking them.
1. Adjust the [Makefile](../Makefile), adding the new `3.3` version. If an old release is not supported anymore, remove it as well from the make targets.
1. Build the image (`make maistra-builder_3.3`). Fix any errors and repeat this step until the build succeeds.
1. Try a build of pure upstream Istio using the image you just built.
   ```sh
   $ git clone -b release-2.2 https://github.com/istio/istio.git
   $ cd istio
   $ export IMG=quay.io/maistra-dev/maistra-builder:3.3
   $ make build
   $ make test
   ```
   If there is any failure (build or test), inspect the errors and verify if it's because a tool is missing, or if the version of a tool is not acurate. Make the necessary adjustements to the Dockerfile, rebuild the image and try again. Repeat until the build succeeds.
1. Commit your changes and submit a pull request to this repository.

It's worth to mention that the steps above are not final. During the developing of a new Maistra version, as people are doing rebases, building, testing, etc it might be necessary to make adjustements to the Dockerfile, adding new tools, fixing variables, paths, etc. This is normal behavior.


## How to develop multi arch builder image locally

References:
- https://github.com/multiarch/qemu-user-static
- https://gist.github.com/tnk4on/93e87652cd50972899bfa2f3949a010b

1. Run qemu-user-static

```
sudo podman run \
    --rm \
    --privileged \
    multiarch/qemu-user-static \
    --reset -p yes
```

2. Run a container with --arch . For example, run a container with base image ubi8

```
sudo podman run -d -t \
    --rm \
    --name test-x86 \
    --arch amd64 \
    --privileged \
    -v /var/lib/docker \
    registry.access.redhat.com/ubi8/ubi:8.8-854 \
    tail -f /dev/null

sudo podman exec -it test-x86 /bin/bash
```

```
sudo podman run -d -t \
    --rm \
    --name test-arm \
    --arch aarch64 \
    --privileged \
    -v /var/lib/docker \
    registry.access.redhat.com/ubi8/ubi:8.8-854 \
    tail -f /dev/null

sudo podman exec -it test-arm /bin/bash
```

```
sudo podman run -d -t \
    --rm \
    --name test-p \
    --arch ppc64le \
    --privileged \
    -v /var/lib/docker \
    registry.access.redhat.com/ubi8/ubi:8.8-854 \
    tail -f /dev/null

sudo podman exec -it test-p /bin/bash
```

```
sudo podman run -d -t \
    --rm \
    --name test-z \
    --arch s390x \
    --privileged \
    -v /var/lib/docker \
    registry.access.redhat.com/ubi8/ubi:8.8-854 \
    tail -f /dev/null

sudo podman exec -it test-z /bin/bash
```

