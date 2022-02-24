# Operating Prow

This section describes the steps needed to get your own Prow instance up and running on an existing cluster. It only covers aspects that are relevant to our configuration. See the [upstream docs](https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md) for more details.

All deployment information is stored in the [cluster](cluster) directory.

## Obtaining Secrets

You should have existing secrets for an already running cluster. You'll only need to obtain them if you're planning to do a test deployment to a different cluster. Note that in order to do that, you should have a separate GitHub Org already setup and configured in `config.yaml`.

### GitHub Bot Account

1. Create bot account with access to your org
1. Create a [personal access token](https://github.com/settings/tokens). We currently only need public_repo and repo:status scopes
1. Store it in `prow/secrets/github-token`

### Webhook HMAC Secret

1. Run `openssl rand -hex 20 > prow/secrets/github-hmac-secret`

### Cookie Secret

1. Run `openssl rand -hex 32 > prow/secrets/cookie-secret`

### GCS Credentials

1. Create a GCS bucket, make it publically readable
1. Create a Service Account, store API credentials in `prow/secrets/gcs-credentials.json`
1. Give the Service Account write permissions to the bucket you created

### COPR Credentials
Some jobs run builds of RPM packages in [COPR](https://copr.fedorainfracloud.org/). In order to do that we need a valid COPR token. Make sure the COPR account associated with this token has the proper permissions to run builds on the desired COPR repository or group.

1. Create a [COPR](https://copr.fedorainfracloud.org/) account (if you don't have one already)
1. Get a token for your account on the [COPR API website](https://copr.fedorainfracloud.org/api/).
1. Save this token into the file `prow/secrets/copr-token-bot`.

## Deploying Prow from Scratch

1. Run `cd prow && ./create.sh`
1. Add the webhook URL to the GitHub Org: `https://github.com/organizations/<org>/settings/hooks`
   - Payload URL: `https://<prow-url>/hook`
   - Content type: `application/json`
   - Secret: the contents of `prow/secrets/github-hmac-secret`

## Known Issues

- Sometimes the letsencrypt certificate retrieval will fail on the second route due to rate limiting. You can copy the certificate over manually in that case.
