# FCGames — UsersAPI

Microsserviço responsável pelo cadastro, autenticação e gestão de usuários da plataforma FCGames.

## Tecnologias

- .NET 10 / ASP.NET Core
- EF Core 10 + SQLite (dev) / PostgreSQL (prod)
- MediatR 14 — CQRS
- FluentValidation 12
- MassTransit 8 + RabbitMQ
- Serilog (logs JSON estruturados)
- JWT Bearer

## Endpoints

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| `POST` | `/usuarios` | Público | Cadastra novo usuário |
| `POST` | `/usuarios/login` | Público | Autentica e retorna JWT |
| `GET` | `/usuarios` | Admin | Lista todos os usuários |
| `GET` | `/usuarios/{id}` | Admin | Busca usuário por ID |
| `PUT` | `/usuarios/{id}` | Admin | Atualiza usuário |
| `GET` | `/health` | Público | Health check |

### Exemplos de request

**POST /usuarios**
```json
{
  "nome": "João Silva",
  "email": "joao@example.com",
  "senha": "MinhaS3nha!"
}
```

**POST /usuarios/login**
```json
{
  "email": "joao@example.com",
  "senha": "MinhaS3nha!"
}
```

**Resposta de login:**
```json
{
  "email": "joao@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiracao": "2025-01-01T01:00:00Z"
}
```

## Variáveis de Ambiente

| Variável | Obrigatória | Padrão | Descrição |
|----------|-------------|--------|-----------|
| `JWT__KEY` | **Sim** | — | Chave secreta para assinar tokens JWT (mínimo 32 chars) |
| `JWT__ISSUER` | Não | `AppFiapFcGames` | Emissor do token JWT |
| `ConnectionStrings__DefaultConnection` | Não | `Data Source=fcgames.db` | Connection string do banco de dados |
| `RabbitMQ__Host` | Não | `localhost` | Host do RabbitMQ |
| `RabbitMQ__Username` | Não | `guest` | Usuário do RabbitMQ |
| `RabbitMQ__Password` | Não | `guest` | Senha do RabbitMQ |
| `NUGET_AUTH_TOKEN` | Build only | — | PAT GitHub com `read:packages` para restaurar `FCGames.IntegrationEvents` |

> **Segurança:** `JWT__KEY` nunca deve estar em `appsettings.json`. Configure sempre via variável de ambiente ou secrets.

## Executando localmente

### Pré-requisitos

- .NET 10 SDK
- GitHub PAT com permissão `read:packages` (para o pacote `FCGames.IntegrationEvents`)

### Configurar PAT do GitHub

```bash
export NUGET_AUTH_TOKEN=ghp_seu_token_aqui   # Linux/Mac
$env:NUGET_AUTH_TOKEN = "ghp_seu_token_aqui"  # PowerShell
```

### Rodar a aplicação

```bash
# Setar variáveis de ambiente necessárias
export JWT__KEY="ChaveSegredoMinimo32Caracteres!!"
export ASPNETCORE_ENVIRONMENT=Development

cd app/src
dotnet run --project Fiap.FCGames.Users.Api
```

A API ficará disponível em `http://localhost:5001`.

- Swagger UI: `http://localhost:5001/swagger`
- Scalar UI: `http://localhost:5001/scalar/v1`

### Seed de dados

Ao iniciar, a aplicação cria automaticamente um usuário Admin padrão se não existir:

| Campo | Valor |
|-------|-------|
| Email | `admin@fcgames.com` |
| Senha | `Admin@123` |

## Build com Docker

```bash
docker build \
  --build-arg NUGET_AUTH_TOKEN=$NUGET_AUTH_TOKEN \
  -t fcgames-users-api:latest .
```

## Eventos publicados

| Evento | Trigger | Consumidores |
|--------|---------|--------------|
| `UserCreatedEvent` | Após cadastro de usuário | CatalogAPI, NotificationsAPI |

## Arquitetura

```
Fiap.FCGames.Users.Api          <- Controllers, Program.cs
Fiap.FCGames.Users.Application  <- CQRS (Commands, Queries, Behaviors)
Fiap.FCGames.Users.Domain       <- Entidades, Interfaces, Excecoes
Fiap.FCGames.Users.Infra        <- EF Core, Repositories, Services
Fiap.FCGames.Users.CrossCutting <- Extensions, Middleware
```
