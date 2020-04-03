# Test Infrastructure

This repository is meant to hold all information required to deploy and run Maistra test infrastructure in an Infrastructe-as-Code fashion.

## Build Container

The build container (`maistra-builder`) is used by Prow to run unit tests and the linters against [`maistra/istio`](https://github.com/maistra/istio). 

To build the `maistra-builder` container image, run `make builder-image` in this repository.

## Prow

This describes the steps needed to get our prow instance up and running on an existing cluster. It only covers aspects that are relevant to our configuration. See the [upstream docs](https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md) for more details.

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

### Deploying Prow from Scratch

1. Run `cd prow && ./create.sh`
1. Add the webhook URL to the GitHub Org: https://github.com/organizations/<org>/settings/hooks - the URL is https://<prow-url>/hook

### Known Issues

- Sometimes the letsencrypt certificate retrieval will fail on the second route due to rate limiting. You can copy the certificate over manually in that case.
