## Using Prow

Prow provides CI features as well as a set of tools to improve developers productivity. Prow was developed by the [Kubernetes community](https://github.com/kubernetes/test-infra/tree/master/prow) and can be deployed in any Kubernetes cluster. In fact Maistra runs its own instance of Prow in https://prow.maistra.io/.

Prow runs pre-submit, post-submit and periodic jobs, but also comes with a set of productivity tools:
* GitHub merge automation with batch testing logic.
* Front end for viewing jobs, merge queue status and more.
* For a full list of Prow features, see [their website](https://github.com/kubernetes/test-infra/tree/master/prow).

Prow is available at https://prow.maistra.io and more details about the plugins can be found on [Prow Command Help section](https://prow.maistra.io/command-help).


### Prow Configuration

There are 2 main configurations:
* [config.gen.yaml](config.gen.yaml): Define jobs, general settings
* [plugins.yaml](plugins.yaml): Plugins configuration

You can find all configuration files in the [`config`](config) directory. Before applying the config, the files in that directory will be concatenated and written to [`config.gen.yaml`](config.gen.yaml), so that file represents what will be applied to the cluster. When changing a file in the `config` directory, make sure to run `make gen` afterwards to generate the concatenated file. 

All commits to this repository's `main` branch will be auto-applied to that cluster. There is a post-submit job that runs after a PR is merged into this repository that will reconfigure the prow instance that runs at https://prow.maistra.io. Yes, this is prow recursively configuring itself 🤯. So, after a PR merged into this repository, you can monitor for the post-submit job status (e.g. by looking at the [commits page](https://github.com/maistra/test-infra/commits/main) and inspecting the symbol next to the commit date; if it's a green ✔️ the job succeeded, if it's a yellow • it's still running). When that job finishes, the prow instance is updated with the new configuration that just got merged.

### Adding Jobs

Jobs are located in the files [`config/presubmits.yaml`](config/presubmits.yaml) and [`config/postsubmits.yaml`](config/postsubmits.yaml). Prow also supports running [periodic](config/periodics.yaml) jobs, but we don't use them so much. A job looks like this:

```yaml
presubmits:
  # the <github org>/<repository> this job is run against
  maistra/istio:
    # the job's name
  - name: unittests
    # `decorate` determines whether to wrap the container image using prow's init containers.
    # This makes sure that workdir is set correctly and you can expect to run your commands
    # in the root of the checked-out repo. It also makes sure logs are uploaded to GCS.
    # You'll generally want to enable this.
    decorate: true
    # you want to set this to true if you don't speficy special change patterns (you can
    # instruct prow to run jobs only if certain files have changed). See upstream docs
    always_run: true
    # for GOPATH aliasing
    path_alias: istio.io/istio
    # if you set `skip_report` to true, Prow won't comment on your PRs or add status fields.
    # the job still shows up on the dashboard though. useful when testing
    skip_report: false
    # which branches to run against
    branches:
      - ^maistra-2.2$
    # these fields will be injected in the spec of the pod that will run your test.
    spec:
      containers:
      # The builder image in which this job will run; see the "docker" directory in the test-infra repository.
      - image: "quay.io/maistra-dev/maistra-builder:2.2"
        # Command to run in the "maistra/istio" repo, with the commit(s) from the PR applied on top of the branch "maistra-2.2".
        command:
        - make
        - test
        env:
        - name: GOFLAGS
          value: -mod=vendor
```

### New Repositories

Repos that previously were not managed by Prow will require some additional steps for jobs to run against them:

* the `maistra-bot` will need Admin access to a repo. This is due to the status-reconciler creating Status fields if they don't yet exist.
* make sure to add at least the `trigger` plugin for your repo in the [`plugins.yaml`](plugins.yaml) file.

## Tide (Merge Bot)
Tide will merge PRs that have been approved and have all required tests passing. If a PR needs to be rebased, a comment will be added to the PR to alert the user.

When merging a PR, Tide will check to ensure that the PR has been tested with the latest changes. This ensures that two conflicting PRs do not get merged. If a PR is approved, but other changes have been merged since the tests were ran, Tide will queue the PR for retesting. Because this process can make it hard to get a large volume of changes merged, Tide will also batch changes together. For example, if 10 PRs were approved at once, Tide would trigger a test with all of these PRs merged together, into a "Batch". If the tests pass, the whole batch will be merged at once.

Tide configuration is stored in [tide.yaml](config/tide.yaml) in the `tide:` section. Tide works by querying GitHub for PRs (with existing or missing labels, GitHub approval, etc...) and attempting to merge them.

### Relevant labels:

These labels, when present on PRs, have special meaning for Tide:
- `okay to merge`: Tide can merge this PR; Without this label, Tide will *not* merge the PR, even if it is approved.
- `don't squash`: Instructs Tide to not squash the commits in the PR (default behavior), keeping the individual commits.
- `merge strategy`: Instructs Tide to use the merge strategy instead of rebase (the default)
- `do-not-merge` and variations: Prevents tide to merge the PR

### Auto mergeable PR's

It is possible to write automation such that no human intervention (like approving a PR) is necessary. To give an example on how this is useful: We can write a small script that updates the `Istio` repository whenever the `API` changes. We put this script in the `Istio` repo so we can invoke it with `make update-api`. While a human being can type this command, inspect the output, commit the results, open a PR in the `Istio` repo, bug someone to approve it and hope for the best, all of this can be automated, since there's no much for a reviewer to review. With that said, one can create a Tide rule that:

- If the PR is open by someone we trust, and
- The PR passes all required tests, and
- If it has the `auto-merge` label, then
- Merge it automatically, without need of a GitHub approval

In fact we make use of this feature in several repositories. An example is the Envoy ↔ Proxy interation:

- When a PR in Envoy is merged, a post-submit job runs in the Proxy repo, running something like `make update-envoy`.
- That jobs commits the result of that command and opens a PR in the Proxy repo, on behalf of the trusted `maistra-bot` user, with the `auto-merge` label. The job of this post-submit job ends here.
- When a PR is open in the Proxy repo, pre-submit jobs (tests) will run, as usual.
- Once the tests pass, since this PR was opened by a trusted user, and it has the `auto-merge` label, Tide will merge it automatically.
- This means that, some time after a PR is merged in Envoy, Proxy will be updated with the changes without any human interaction.

More updated information about [tide](https://github.com/kubernetes/test-infra/tree/master/prow/cmd/tide).

Tide's status can be found on the [status page](https://prow.maistra.io/tide).

### Why isn't my PR merging?

Tide will post a status explaining why a PR is not ready to merge, indicating the PR needs an approval or a test has failed for example.

Occasionally, every check will pass, but the PR is not merged. This is likely because Tide is waiting for a batch to complete, or the PR is queued for a retest. In these cases, the `tide` status will indicate the PR is in the merge pool, with a link to the [status page](https://prow.maistra.io/tide) with more info.

## Operating Prow

[This page](OPERATING.md) describes the installation and maintaince of a Prow instance in a Kubernetes cluster.
