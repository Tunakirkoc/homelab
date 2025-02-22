# Install BlueMap

## Deploying CloudNativePG operator

First, add the CloudNativePG Helm repository and install the CloudNativePG operator:

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg \
  --namespace cnpg-system \
  --create-namespace \
  cnpg/cloudnative-pg

kubectl get deploy -n cnpg-system cnpg-controller-manager
```

This will install the CloudNativePG operator in the `cnpg-system` namespace.

## Deploying BlueMap

Create a new namespace for the BlueMap deployment:

```bash
kubectl create namespace minecraft
```

To deploy BlueMap, apply the `deploy.yaml` file:

```bash
kubectl apply -f deploy.yaml
```

This command will create a PostgreSQL cluster and a will deply BlueMap in the `minecraft` namespace.

## Deploying BlueMap

BlueMap is deployed as a Kubernetes deployment, service, and ingress. The deployment uses the PostgreSQL instance for storing map data.

The `deploy.yaml` file includes the following resources:

- **PostgreSQL Cluster**: A PostgreSQL instance managed by the CloudNativePG operator.
- **Deployment**: The BlueMap application container.
- **Service**: Exposes the BlueMap application on port 8100.
- **Ingress**: Configures access to BlueMap via an Ingress resource with TLS enabled using Let's Encrypt.

To deploy BlueMap, apply the `deploy.yaml` file:

```bash
kubectl apply -f deploy.yaml
```

## Accessing BlueMap

Once deployed, BlueMap will be accessible at `https://map.kirkoc.net`. Ensure that your DNS is configured to point to your Kubernetes cluster and that the Ingress controller is properly set up.

## Additional Configuration

BlueMap configuration files are located in the `config` directory. You can customize the map settings, storage configuration, and web server settings as needed.

For more information on BlueMap configuration, refer to the [BlueMap documentation](https://bluemap.bluecolored.de/wiki/).

## Retrieving PostgreSQL credentials

To retrieve the PostgreSQL credentials stored in Kubernetes secrets, use the following commands:

```bash
kubectl get secret bluemap-cluster-app -n minecraft -o jsonpath="{.data.uri}" | base64 --decode
kubectl get secret bluemap-cluster-app -n minecraft -o jsonpath="{.data.username}" | base64 --decode
kubectl get secret bluemap-cluster-app -n minecraft -o jsonpath="{.data.password}" | base64 --decode
```

## Docker Image

The Docker image for BlueMap is built and published using GitHub Actions. The workflow file `.github/workflows/bluemap-publish.yml` defines the steps for building and pushing the Docker image to GitHub Container Registry.

## Conclusion

This guide provides a basic setup for running BlueMap on a Kubernetes cluster. You can further customize and extend the setup based on your requirements.
