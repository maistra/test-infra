# Test Infrastructure

This repository is meant to hold all information required to deploy and run Maistra test infrastructure in an Infrastructe-as-Code fashion.

The idea is to have jobs that run automatically for every pull request on Maistra repositories.

This is the regular lifecycle of a pull request in Maistra repositories:

```
              ↗ Pre-submit jobs run and all required tests pass
PR is created → PR gets at least one approval
      ↓       ↘ The label "okay-to-merge" is added to the PR
      ↓
      ↓
When all conditions above are satisfed, then
      ↓
      ↓
      ↓
PR is automatically merged → Post-submit jobs (if any) run
```

There are two main components in this repository:

 - **Builder Containers**: Dockerfiles for containers that run the jobs. Every job runs inside a container, and there is one container image for each maistra branch. For example, pull requests created against branch `maistra-2.2` will trigger a job that runs within a `maistra-builder:2.2` container. See the [docker](docker) directory for more information.

 - **Prow jobs**: Orchestration of the tests that will run automatically. It contains all the rules that determine which jobs will run for each repository and branches. See the [prow](prow) directory for more information.

TEST
