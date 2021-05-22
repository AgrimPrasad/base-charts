# Base Helm Charts

This repository is intended to be used as a base helm chart repository to deploy applications without re-inventing the wheel every time.

Goals:

1. Define 1 (or at most few) base helm charts per deployment target (e.g. GKE Kubernetes) on which applications should be based on for deployment.

1. Keep it simple. Deployment using raw github links, not fancy helm repo servers.

## Adding/Updating base helm chart

Adding a new base helm chart should only need to be performed once (or at most a few times) per deployment target (e.g. GKE Kubernetes).

### Adding base helm chart

Create a new helm chart called `deployment-chart` and update the repository.

```sh
NAME=deployment-chart make create # runs `helm create deployment-chart`
NAME=deployment-chart make bump # runs `helm package` and `helm repo index`
```

### Updating an existing base helm chart

You may want to add new resources to the base helm chart in exceptional circumstances, for example if a kubernetes `Job` is required. In this case, add the new resource using standard Kubernetes YAML within `deployment-chart/templates/<new-resource>.yaml`.

Update the `version` of the existing base helm chart in `deployment-chart/Chart.yaml` file of the helm chart before running `make bump` as above.

```sh
NAME=deployment-chart make bump # AFTER the base helm chart version has been updated
```

## Using base helm chart

After a base helm chart has been created, you can use it to deploy to its deployment target (e.g. GKE Kubernetes).

1. Add the helm repo to your local list of help repos.

   ```sh
   helm repo add base-charts 'https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/'
   helm repo update
   ```

2. Prepare a helm `values` file specific to the environment you are deploying too. A sample [`deployment-chart/values.yaml`](./deployment-chart/values.yaml) file is provided here which acts as the base `values.yaml` file for your deployment. You should specify any overrides to this `values.yaml` file in your own repo with a separate `values-<env>.yaml` file.

3. Deploy using `helm install` or `helm template` commands while providing your own `values-<env>.yaml` file as mentioned above to override helm chart values. For example, to deploy to GKE, pipe the YAML output of `helm template` to the [`gke-deploy`](https://cloud.google.com/build/docs/deploying-builds/deploy-gke) tool provided by GCP. Note that `gke-deploy` is a GKE-specific convenience wrapper around `kubectl`, so you can use a similar command to deploy with `kubectl` directly into any Kubernetes server environment.

   ```sh
       helm template --name-template=$(APP_NAME) \
       --set image.tag=latest \
       --set secrets.SUPER_SECRET_KEY=$(SUPER_SECRET_KEY) \
       --values=./values-<env>.yaml \
       --repo=https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/ deployment-chart \
       | gke-deploy run --filename - --app $(APP_NAME) --cluster $(CLUSTER_NAME) --project $(CLUSTER_PROJECT) --location $(CLUSTER_REGION)
   ```
