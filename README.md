# Test Infrastructure

This repository is meant to hold all information required to deploy and run Maistra test infrastructure in an Infrastructe-as-Code fashion.

There are two main components in this repository:

- **Builder Images**: Dockerfiles for containers that run the jobs. Every job runs inside a container, and there is one container image for each maistra branch. For example, pull requests created against branch `maistra-2.5` will trigger a job that runs within a `maistra-builder:2.5` container. See the [docker](docker) directory for more information.

- **Utilities**: Miscelaneous utilities (mainly shell scripts) used in automation jobs.
