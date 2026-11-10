# users-api em Kubernetes local (Kind / Docker Desktop)

Manifests só para cluster local. Na AWS o deploy usa `fcg-orchestration/k8s/eks`.

0. Gere a imagem com a tag que o `deployment.yaml` espera (no Kind, carregue no cluster):

```bash
docker build --secret id=GITHUB_TOKEN,env=NUGET_AUTH_TOKEN -t fcg-users-api:latest .
kind load docker-image fcg-users-api:latest    # só no Kind; o Docker Desktop já enxerga a imagem
```

1. Crie o Secret real (o `secret.yaml` daqui é só modelo, com `REPLACE_ME`):

```bash
kubectl create secret generic users-api-secret -n fcgames \
  --from-literal=jwt-key="$JWT__KEY" \
  --from-literal=db-connection="Data Source=/data/users.db" \
  --from-literal=rabbitmq-username="$RABBITMQ__USERNAME" \
  --from-literal=rabbitmq-password="$RABBITMQ__PASSWORD" \
  --from-literal=admin-password="$ADMIN__PASSWORD"
```

2. Aplique os demais manifests (não use `kubectl apply -f k8s/`: aplicaria o modelo por cima do Secret):

```bash
kubectl apply -f k8s/configmap.yaml -f k8s/deployment.yaml -f k8s/pvc.yaml -f k8s/service.yaml
```

3. Teste:

```bash
kubectl get pods -n fcgames -l app=users-api
kubectl port-forward -n fcgames svc/users-api 5001:80    # http://localhost:5001/health
```

Precisa do RabbitMQ no namespace `fcgames` (manifests em `fcg-orchestration/k8s`).
