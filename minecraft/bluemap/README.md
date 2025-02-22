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

Deploy PostgreSQL and BlueMap using the provided Kubernetes manifests:

```bash
# Deploy PostgreSQL cluster
kubectl apply -f postgresql.yaml

# Wait for PostgreSQL to be ready
kubectl wait --namespace minecraft --for=condition=Ready cluster/bluemap-cluster --timeout=300s

# Deploy BlueMap
kubectl apply -f bluemap.yaml

# Wait for BlueMap to be ready
kubectl wait --namespace minecraft --for=condition=Ready pod -l app=bluemap --timeout=300s
```

This will:
1. Create a PostgreSQL cluster with external access
3. Deploy BlueMap with the configured PostgreSQL database
4. Make BlueMap accessible through a LoadBalancer service

## Accessing BlueMap

Once deployed, BlueMap will be accessible at `https://map.kirkoc.net`. Ensure that your DNS is configured to point to your Kubernetes cluster and that the Ingress controller is properly set up.

## Additional Configuration

BlueMap configuration files are located in the `config` directory. You can customize the map settings, storage configuration, and web server settings as needed.

For more information on BlueMap configuration, refer to the [BlueMap documentation](https://bluemap.bluecolored.de/wiki/).

## Retrieving PostgreSQL credentials

To retrieve the PostgreSQL credentials stored in Kubernetes secrets, use the following commands:

```bash
kubectl get secret bluemap-cluster-app -n minecraft -o jsonpath="{.data.jdbc-uri}" | base64 --decode
```

## Docker Image

The Docker image for BlueMap is built and published using GitHub Actions. The workflow file `.github/workflows/bluemap-publish.yml` defines the steps for building and pushing the Docker image to GitHub Container Registry.

## Conclusion

This guide provides a basic setup for running BlueMap on a Kubernetes cluster. You can further customize and extend the setup based on your requirements.
