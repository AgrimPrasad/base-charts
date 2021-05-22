# Base Helm Charts

This repository is intended to be used as a base helm chart repository to deploy applications without re-inventing the wheel every time.

Goals:

1. Define 1 (or at most few) base helm charts per deployment target (e.g. GKE Kubernetes) on which applications should be based on for deployment.

1. Keep it simple. Deployment using raw github links, not fancy helm repo servers.

## Adding/Updating base helm chart

Adding a new base helm chart should only need to be performed once (or at most a few times) per deployment target (e.g. GKE Kubernetes).

### Adding base helm chart

Create a new helm chart and update the repository.

```sh
NAME=deployment-chart make create # runs `helm create deployment-chart`
NAME=deployment-chart make bump # runs `helm package` and `helm repo index`
```

### Updating an existing base helm chart

If a base helm chart exists already, update its version in `Chart.yaml` file of the helm chart before running `make bump` as above

```sh
NAME=deployment-chart make bump # runs `helm package` and `helm repo index`
```

## Using base helm chart

After a base helm chart has been created, you can use it to deploy to its deployment target (e.g. GKE Kubernetes).

1. Add the helm repo to your local list of help repos.

   ```sh
   helm repo add base-charts 'https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/'
   helm repo update
   ```

2. Prepare a helm `values` file specific to the environment you are deploying too. A sample [`values.yaml`](./values.yaml) file is provided here as reference.

3. Deploy using `helm install` or `helm template` commands. For example, to deploy to GKE, pipe the YAML output of `helm template` to the [`gke-deploy`](https://cloud.google.com/build/docs/deploying-builds/deploy-gke) provided by GCP. Note that `gke-deploy` is a GKE-specific convenience wrapper around `kubectl`, so you can use a similar command to deploy with `kubectl` directly to any Kubernetes server environment.

   ```sh
       helm template --name-template=$(APP_NAME) \
       --set image.tag=latest \
       --set secrets.SUPER_SECRET_KEY=$(SUPER_SECRET_KEY) \
       --values=./values.yaml \
       --repo=https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/ deployment-chart \
       | gke-deploy run -f - -a $(APP_NAME) -o output-prod -c $(CLUSTER_NAME) --project $(CLUSTER_PROJECT) -l $(CLUSTER_REGION)
   ```
