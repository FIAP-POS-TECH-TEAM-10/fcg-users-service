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

```bash
kubectl apply -f k8s/
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

**IMPORTANTE**: Altere os valores dos Secrets em produção!

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
DB_CONNECTION: Data Source=/data/users.db
RabbitMQ__Host: rabbitmq
RabbitMQ__Username: guest
RabbitMQ__Password: guest
JWT__KEY: <secret>
JWT__ISSUER: AppFiapFcGames
```
