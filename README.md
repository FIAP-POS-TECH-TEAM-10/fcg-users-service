# fcg-users-service (UsersAPI)

Cadastro, login e gestão de usuários do FCGames. É o **único serviço que emite JWT**; os outros só
validam o token. Ao cadastrar um usuário, publica `UsuarioCriadoEvento`.

## Endpoints

| Endpoint | Acesso | O que faz |
|---|---|---|
| `POST /usuarios` | anônimo | cadastra usuário (publica `UsuarioCriadoEvento`) |
| `POST /usuarios/login` | anônimo | devolve o JWT |
| `GET /usuarios` | Admin | lista usuários |
| `GET /usuarios/{id}` | Admin | busca por id |
| `PUT /usuarios/{id}` | Admin | atualiza |
| `GET /health` · `GET /health/live` | anônimo | health checks |
| `GET /metrics` | anônimo | métricas Prometheus |

Na primeira subida o app cria o admin `admin@fcgames.com` com a senha de `ADMIN__PASSWORD`.
Contrato do evento: [`fcg-integration-events`](https://github.com/FIAP-POS-TECH-TEAM-10/fcg-integration-events).

## Variáveis de ambiente

| Variável | Obrigatória | O que é |
|---|---|---|
| `JWT__KEY` | sim | chave de assinatura do JWT (mín. 32 caracteres) |
| `JWT__ISSUER` | não (`AppFiapFcGames`) | emissor do token |
| `ADMIN__PASSWORD` | sim | senha do admin criado no seed; sem ela o app não sobe |
| `ConnectionStrings__DefaultConnection` | não (`Data Source=fcgames.db`) | SQLite |
| `Messaging__Provider` | não | `Sqs` = SQS/SNS (AWS); vazio + `RabbitMQ__Host` = RabbitMQ; nenhum = em memória |
| `AWS__Region` | não (`sa-east-1`) | região do SQS/SNS |
| `RabbitMQ__Host` · `RabbitMQ__Username` · `RabbitMQ__Password` | com RabbitMQ | broker local |

Nenhum segredo fica no repositório: localmente vêm do `.env` do
[`fcg-orchestration`](https://github.com/FIAP-POS-TECH-TEAM-10/fcg-orchestration); no EKS, dos
Secrets `fcg-jwt` e `fcg-admin`.

## Rodar local

Jeito recomendado: `docker compose up` no `fcg-orchestration` (sobe tudo). Só este serviço:

```bash
export NUGET_AUTH_TOKEN=$(gh auth token)   # pacote FCGames.IntegrationEvents (read:packages)
export JWT__KEY="<32+ caracteres>" ADMIN__PASSWORD="<senha>" ASPNETCORE_ENVIRONMENT=Development
dotnet run --project app/src/Fiap.FCGames.Users.Api      # http://localhost:5001 (Swagger em /swagger)
dotnet test app/src/Fiap.FCGames.Users.slnx
```

Imagem: `docker build --secret id=GITHUB_TOKEN,env=NUGET_AUTH_TOKEN -t fcg-users-service .`

## Na AWS

- Pod `users-api` no cluster EKS `fcg-eks` (namespace `fcgames`), atrás do ALB em `/usuarios`.
- Imagem no ECR `fcg-users-service`. Mensageria por SQS/SNS com a role `fcg-eks-users-api` (Pod Identity).
- SQLite em disco efêmero: cada deploy zera os usuários e recria o admin.
- Manifests e infra: `fcg-orchestration/k8s/eks` e `fcg-orchestration/infra/eks`.

## CI/CD

`.github/workflows/ci-cd.yml`: PR → build, testes, imagem e Trivy. Merge na `main` → também push no
ECR (`:<sha7>`, `:latest`) e rolling update no EKS; com o cluster desligado o deploy é pulado e a
imagem entra no próximo "Ligar". Alertas do Trivy na aba **Security → Code scanning**.

Para Kind/Docker Desktop local, ver [`k8s/README.md`](k8s/README.md).
