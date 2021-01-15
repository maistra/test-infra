# Issues for this repository are disabled

Issues for this repository are tracked in Red Hat Jira. Please head to <https://issues.redhat.com/browse/MAISTRA> in order to browse or open an issue.

# Test Infrastructure

This repository is meant to hold all information required to deploy and run maistra test infrastructure in an Infrastructe-as-Code fashion.

## Build Container

The build container (`maistra-builder`) is used by Prow to run unit tests and the linters against [`maistra/istio`](https://github.com/maistra/istio). 

To build the `maistra-builder` container image locally, run `make maistra-builder` in this repository. It will build all available versions of the container; generally, one per maistra minor version: 1.0, 1.1, etc.

## Using Prow

The official maistra Prow instance is available at https://prow.maistra.io. All commits to this repository's `main` branch will be auto-applied to that cluster.

### Prow Configuration

You can find all configuration files (including jobs, see next chapter) in the `prow/config` directory. Before applying the config, the files in that directory will be concatenated and written to `prow/config.gen.yaml`, so that file represents what will be applied to the cluster. When changing a file in the `prow/config` directory, make sure to run `make gen` afterwards to generate the concatenated file. 

### Adding Jobs

All jobs are located in the files `prow/config/presubmits.yaml` and `prow/config/postsubmits.yaml`. Prow also supports running periodical jobs, but we don't currently use that. A job looks like this:

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
      - maistra-1.1
    # these fields will be injected in the spec of the pod that will run your test.
    spec:
      containers:
      - image: "registry.gitlab.com/dgrimm/istio/maistra-builder:1.1"
        command:
        - make
        - init
        - test
        env:
        - name: GOFLAGS
          value: -mod=vendor
```

#### New Repositories

Repos that previously were not managed by Prow will require some additional steps for jobs to run against them:

* the `maistra-bot` will need Admin access to a repo. This is due to the status-reconciler creating Status fields if they don't yet exist.
* make sure to add at least the `trigger` plugin for your repo in the `prow/plugins.yaml`


## Operating Prow

This section describes the steps needed to get your own Prow instance up and running on an existing cluster. It only covers aspects that are relevant to our configuration. See the [upstream docs](https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md) for more details.

### Obtaining Secrets

You should have existing secrets for an already running cluster. You'll only need to obtain them if you're planning to do a test deployment to a different cluster. Note that in order to do that, you should have a separate GitHub Org already setup and configured in `config.yaml`.

#### GitHub Bot Account

1. Create bot account with access to your org
1. Create a [personal access token](https://github.com/settings/tokens). We currently only need public_repo and repo:status scopes
1. Store it in `prow/secrets/github-token`

#### Webhook HMAC Secret

1. Run `openssl rand -hex 20 > prow/secrets/github-hmac-secret`

#### Cookie Secret

1. Run `openssl rand -hex 32 > prow/secrets/cookie-secret`

#### GCS Credentials

1. Create a GCS bucket, make it publically readable
1. Create a Service Account, store API credentials in `prow/secrets/gcs-credentials.json`
1. Give the Service Account write permissions to the bucket you created

#### COPR Credentials
Some jobs run builds of RPM packages in [COPR](https://copr.fedorainfracloud.org/). In order to do that we need a valid COPR token. Make sure the COPR account associated with this token has the proper permissions to run builds on the desired COPR repository or group.

1. Create a [COPR](https://copr.fedorainfracloud.org/) account (if you don't have one already)
1. Get a token for your account on the [COPR API website](https://copr.fedorainfracloud.org/api/).
1. Save this token into the file `prow/secrets/copr-token-bot`.

### Deploying Prow from Scratch

1. Run `cd prow && ./create.sh`
1. Add the webhook URL to the GitHub Org: `https://github.com/organizations/<org>/settings/hooks`
   - Payload URL: `https://<prow-url>/hook`
   - Content type: `application/json`
   - Secret: the contents of `prow/secrets/github-hmac-secret`

### Known Issues

- Sometimes the letsencrypt certificate retrieval will fail on the second route due to rate limiting. You can copy the certificate over manually in that case.
