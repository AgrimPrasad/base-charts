# Base Helm Charts

This repository is intended to be used as a base helm chart repository to deploy applications without re-inventing the wheel every time.

Goals:

1. Define 1 (or at most few) base helm charts per deployment target (e.g. GKE Kubernetes) on which applications should be based on for deployment.

1. Keep it simple. Deployment using raw github links, not fancy helm repo servers.

## Using a base helm chart

You can use one of the existing base helm charts defined here (currently the `deployment-chart` base helm chart) to deploy to its intended deployment target (e.g. GKE Kubernetes for the `deployment-chart` base helm chart).

1. Add the helm repo to your local list of help repos.

   ```sh
   helm repo add base-charts 'https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/'
   helm repo update
   ```

2. Prepare a helm `values` file specific to the environment you are deploying to. A sample [`deployment-chart/values.yaml`](./deployment-chart/values.yaml) file is provided here which acts as the base `values.yaml` file for your deployment. You should specify any overrides to this `values.yaml` file in your own repo with a separate `values-<env>.yaml` file.

3. Deploy using `helm install` or `helm template` commands while providing your own `values-<env>.yaml` file as mentioned above to override helm chart values. For example, to deploy to GKE, pipe the YAML output of `helm template` to the [`gke-deploy`](https://cloud.google.com/build/docs/deploying-builds/deploy-gke) tool provided by GCP. Note that `gke-deploy` is a GKE-specific convenience wrapper around `kubectl`, so you can use similar commands to deploy with `kubectl` directly into any Kubernetes server environment.

   ```sh
       helm template --name-template=$(APP_NAME) \
       --set image.tag=latest \
       --set secrets.SUPER_SECRET_KEY=$(SUPER_SECRET_KEY) \
       --values=./values-<env>.yaml \
       --repo=https://raw.githubusercontent.com/AgrimPrasad/base-charts/master/ deployment-chart \
       | gke-deploy run --filename - \
       --app $(APP_NAME) \
       --cluster $(CLUSTER_NAME) \
       --project $(CLUSTER_PROJECT) \
       --location $(CLUSTER_REGION)
   ```

## `deployment-chart` base helm chart customizations

The `deployment-chart` base helm chart provided in this repo has the following additional modifications on top of the standard helm chart generated with `helm create`.

Please refer to files within `deployment-chart/templates/` for implementation details.

- Pod `anti-affinity` can be easily configured using the following `values.yaml` file entries.

  - `soft` antiAffinity provides this feature at pod schedule time only (best-effort)

  ```yaml
  antiAffinity: "soft"
  ```

  - `hard` antiAffinity ensures that pods end up on different nodes

  ```yaml
  antiAffinity: "hard"
  ```

- Node affinity can be configured for pods. This can be used to ensure that pods end up or don't end up on specific nodes. For example, for pods which require nodes with GPU available on GKE:

  ```yaml
  nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
     nodeSelectorTerms:
        - matchExpressions:
           - key: cloud.google.com/gke-accelerator
              operator: Exists
  ```

- Default Horizontal Pod Autoscaler (HPA) `autoscaling` values have been modified to use explicit resource values as opposed to target CPU/memory percentages. This is because these percentage values are unintuitively based on the resource limits as opposed to resource request values. Example

  ```yaml
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 3
    targetCPUAverageValue: 100m # autoscale at 100m CPU explicitly
    targetMemoryAverageValue: 200Mi # autoscale at 200Mi Memory explicitly
  ```

- The base `values` file at `deployment-chart/values.yaml` explicitly specifies low requests and high limits values by default. This is as per usual Ops guidance to always test with low resource request values initially until your app can comfortably start up and run at some sane resource values. Without these default values, your app could start up and use up infinite resources due to bugs.

  Default values in `deployment-chart/values.yaml`:

  ```yaml
  resources:
    limits:
      cpu: 200m # arbitrarily high, adjust as per usage
      memory: 400Mi # arbitrarily high, adjust as per usage
    requests:
      cpu: 5m # arbitrarily low, adjust as per usage
      memory: 20Mi # arbitrarily low, adjust as per usage
  ```

- Ability to add multiple kubernetes service ports and annotations if desired. The optional service annotations can be useful in several environments, e.g. in orderto configure [GKE container-native load balancing](https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing) for better GKE ingress performance.

  ```yaml
  service:
   type: ClusterIP
   ports:
      - name: http
         port: 80
         targetPort: http
         protocol: TCP
   annotations:
      # following indicates that we use container-native load-balancing
      cloud.google.com/neg: '{"ingress": true}'
  ```

- [Container liveness/readiness/startup probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#:~:text=The%20kubelet%20uses%20startup%20probes,interfere%20with%20the%20application%20startup.) which are very important in ensuring that applicaton pods can start up properly and be recycled if their health checks start failing.

  You can enable these with default values in your `values-<env>.yaml` file as follows. This assumes a health check endpoint in your app at path `/health` and port 80. You can override these default values as usual if needed.

  ```yaml
  probes:
    liveness:
      enabled: true
    readiness:
      enabled: true
    startup:
      enabled: true
  ```

- `deployment-chart/deployment.yaml` provides additional environment variables to the runtime pod which are available from Kubernetes, such as pod name, pod IP address etc. In addition, sane defaults are used, such as a `rollingUpdate` strategy with `maxSurge: 1` and `maxUnavailable: 0` to ensure graceful rolling out of applications.

- `deployment-chart/secret.yaml`: Allows you to add kubernetes secrets to the application pods as runtime environment variables.

## Adding/Updating base helm charts

Adding a new base helm chart should only need to be performed once (or at most a few times) per deployment target (e.g. GKE Kubernetes).

### Adding a new base helm chart

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
