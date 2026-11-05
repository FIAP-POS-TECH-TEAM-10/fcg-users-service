# Users API - Kubernetes Deployment

Este diretório contém os manifestos Kubernetes para deploy do microsserviço Users API.

## Recursos

- **Deployment**: Define os Pods da aplicação
- **Service**: Expõe a API dentro do cluster
- **ConfigMap**: Configurações não sensíveis
- **Secret**: Credenciais e dados sensíveis (JWT Key, connection string)
- **PersistentVolumeClaim**: Volume para persistir o banco de dados SQLite

## Deploy

### 1. Build da Imagem Docker

```bash
docker build -t fcg-users-api:latest .
```

### 2. Aplicar Manifestos

> **Atenção:** crie o Secret (seção abaixo) **antes** de aplicar e não use `kubectl apply -f k8s/` na pasta inteira: isso aplicaria o `secret.yaml` modelo (valores `REPLACE_ME`) por cima do Secret real.

```bash
kubectl apply -f k8s/configmap.yaml -f k8s/deployment.yaml -f k8s/pvc.yaml -f k8s/service.yaml
```

### 3. Verificar Status

```bash
kubectl get pods -n fcgames -l app=users-api
kubectl logs -n fcgames -l app=users-api -f
```

## Configurações

### ConfigMap (configmap.yaml)
- `jwt-issuer`: Issuer do token JWT
- `rabbitmq-host`: Host do RabbitMQ
- `aspnetcore-urls`: URLs que a aplicação escuta

### Secret (secret.yaml)
- `jwt-key`: Chave secreta para assinar tokens JWT
- `db-connection`: String de conexão do banco de dados
- `rabbitmq-username`: Usuário do RabbitMQ
- `rabbitmq-password`: Senha do RabbitMQ
- `admin-password`: Senha do usuário `admin@fcgames.com` criado na primeira subida (sem ela o app não sobe)

**IMPORTANTE**: Altere os valores dos Secrets em produção!

O `secret.yaml` versionado é só um **modelo** (valores `REPLACE_ME`). Crie o Secret real com as suas credenciais:

```bash
kubectl create secret generic users-api-secret -n fcgames \
  --from-literal=jwt-key="$JWT__KEY" \
  --from-literal=db-connection="Data Source=/data/users.db" \
  --from-literal=rabbitmq-username="$RABBITMQ__USERNAME" \
  --from-literal=rabbitmq-password="$RABBITMQ__PASSWORD" \
  --from-literal=admin-password="$ADMIN__PASSWORD"
```

## Acesso

### Port Forward para acesso local

```bash
kubectl port-forward -n fcgames svc/users-api 5001:80
```

Acesse: http://localhost:5001

## Endpoints

- `POST /api/usuarios` - Criar usuário
- `POST /api/usuarios/login` - Autenticar usuário
- `GET /api/usuarios` - Listar usuários
- `GET /api/usuarios/{id}` - Buscar usuário por ID
- `PUT /api/usuarios/{id}` - Atualizar usuário
- `GET /health` - Health check

## Dependências

- RabbitMQ (deve estar rodando no namespace fcgames)

## Variáveis de Ambiente

As variáveis são injetadas automaticamente do ConfigMap e Secret:

```yaml
ASPNETCORE_URLS: http://+:5001
ConnectionStrings__DefaultConnection: Data Source=/data/users.db
RabbitMQ__Host: rabbitmq
RabbitMQ__Username: <secret>
RabbitMQ__Password: <secret>
JWT__KEY: <secret>
JWT__ISSUER: AppFiapFcGames
```
