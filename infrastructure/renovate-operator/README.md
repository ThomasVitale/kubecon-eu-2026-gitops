# Renovate Operator

[Renovate Operator](https://github.com/mogenius/renovate-operator) runs Renovate on a schedule inside the cluster and provides a web UI to follow and trigger the runs.

Flux deploys it through two Kustomizations defined in `clusters/cloud/infrastructure.yml`:

- `renovate-operator` applies this folder: the namespace and the Helm chart, which installs the operator and its CRDs.
- `renovate-jobs` applies `infrastructure/renovate-jobs`: the `RenovateJob` that defines which repositories Renovate manages and when. It depends on `renovate-operator`, so the CRDs exist before the job is applied.

## Access

The UI is exposed at <https://renovate.cloud.thomasvitale.dev> through the `external` gateway and requires a GitHub login.

GitHub login cannot restrict who signs in: any GitHub user can complete the login. Access is enforced afterwards by the operator. Only the accounts listed in `authorization.defaults.adminUsers` (`ThomasVitale`) see the RenovateJobs; everyone else gets an empty dashboard, where jobs answer 404 and actions 403. Anonymous access is disabled, for both the dashboard and the Renovate logs.

To add someone, add their GitHub login to `adminUsers` (full access) or `readerUsers` (read-only) in `release.yml`.

## Before deploying

### 1. Check the cluster

```shell
flux version                                            # controllers must be v2.6 or later
kubectl -n envoy-gateway-system get gateway external    # the shared gateway with an https listener
dig +short renovate.cloud.thomasvitale.dev              # must resolve to the gateway's load balancer
```

If DNS returns nothing, add an A record (or a wildcard `*.cloud.thomasvitale.dev`) pointing to the load balancer, the same as `grafana.cloud.thomasvitale.dev`.

### 2. Create the GitHub OAuth App (UI login)

On GitHub, go to Settings → Developer settings → **OAuth Apps** → New OAuth App:

- Application name: `Renovate Operator`
- Homepage URL: `https://renovate.cloud.thomasvitale.dev`
- Authorization callback URL: `https://renovate.cloud.thomasvitale.dev/auth/callback`
- Enable Device Flow: unchecked

Once created, copy the **Client ID** and generate a **client secret**.

### 3. Set the client ID

In `release.yml`, replace `<github-oauth-app-client-id>` with the Client ID. It is not a secret, so it can be committed.

### 4. Create the fine-grained PAT (Renovate)

On GitHub, go to Settings → Developer settings → **Fine-grained tokens** → Generate new token:

- Resource owner: `ThomasVitale`
- Repository access: **Only select repositories**, the ones listed in `discoveryFilters` in `infrastructure/renovate-jobs/renovatejob.yml`
- Repository permissions:
  - Contents: Read and write
  - Issues: Read and write
  - Pull requests: Read and write
  - Workflows: Read and write (required to update GitHub Actions in `.github/workflows`)
  - Metadata: Read-only (added automatically)

### 5. Create the namespace and the secrets

The secrets live in the `renovate-operator` namespace, so create it first. Flux takes it over on the first sync.

```shell
kubectl create namespace renovate-operator
kubectl label namespace renovate-operator pod-security.kubernetes.io/enforce=restricted

kubectl create secret generic github-oauth-secret \
  --from-literal=client-secret='<oauth-client-secret-from-step-2>' \
  --from-literal=session-secret="$(openssl rand -hex 32)" \
  --namespace renovate-operator

kubectl create secret generic renovate-secret \
  --from-literal=GITHUB_COM_USER=ThomasVitale \
  --from-literal=GITHUB_COM_TOKEN='<pat-from-step-4>' \
  --from-literal=RENOVATE_TOKEN='<pat-from-step-4>' \
  --namespace renovate-operator
```

The session secret keeps UI sessions valid across operator restarts. Do NOT commit real secrets to git.

### 6. Avoid duplicate pull requests

If the hosted Renovate GitHub App is installed, go to Settings → Applications → **Renovate** → Configure and remove its access to the repositories managed here. Otherwise both will open the same pull requests.

### 7. Commit and push

Flux picks up the changes on the next sync.

## Verify

```shell
flux get kustomizations -n kadras-system renovate-operator renovate-jobs
flux get helmreleases -n renovate-operator
kubectl -n renovate-operator get pods,httproute,renovatejob
```

Open <https://renovate.cloud.thomasvitale.dev> and sign in with GitHub. You should see the `renovate-github` job. If the dashboard is empty, check that your GitHub login matches the entry in `adminUsers`.

The first discovery runs at the next hourly tick of the job's schedule. To start it immediately, use the setup guide in the UI at `/setup`.

Signing in with a different GitHub account should show no jobs.

## Maintenance

- **Chart upgrades**: the `OCIRepository` follows `6.9.x`. Bump the semver range in `release.yml` for minor or major versions, after reading the [changelog](https://github.com/mogenius/renovate-operator/blob/main/CHANGELOG.md).
- **More repositories**: add them to `discoveryFilters` in `infrastructure/renovate-jobs/renovatejob.yml` (or use `ThomasVitale/*`), and grant the PAT access to them.
- **Token expiry**: fine-grained PATs expire. When the PAT is renewed, update `renovate-secret`:

  ```shell
  kubectl -n renovate-operator create secret generic renovate-secret \
    --from-literal=GITHUB_COM_USER=ThomasVitale \
    --from-literal=GITHUB_COM_TOKEN='<new-pat>' \
    --from-literal=RENOVATE_TOKEN='<new-pat>' \
    --dry-run=client -o yaml | kubectl apply -f -
  ```

- **Suspending runs**: set `spec.suspend: true` on the `RenovateJob` in git. Suspending from the UI is disabled, because Flux would revert it on the next sync.
