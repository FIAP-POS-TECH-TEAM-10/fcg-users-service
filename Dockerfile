# ------------------------------------------------------------------------------
# Estágio 1: Build & Publish (Utiliza a imagem do SDK)
# ------------------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Recebe o token enviado pelo GitHub Actions durante o build
ARG GITHUB_TOKEN
ENV NUGET_AUTH_TOKEN=${GITHUB_TOKEN}

COPY nuget.config .
COPY app/src/ app/src/

WORKDIR /src/app/src

# Restaura e publica a aplicação usando o Mount Secret para segurança do Token
RUN --mount=type=secret,id=GITHUB_TOKEN \
    export NUGET_AUTH_TOKEN=$(cat /run/secrets/GITHUB_TOKEN) && \
    dotnet publish Fiap.FCGames.Users.Api/Fiap.FCGames.Users.Api.csproj \
      -c Release \
      -o /app/publish \
      /p:UseAppHost=false

# ------------------------------------------------------------------------------
# Estágio 2: Runtime (Imagem leve para execução no ECS)
# ------------------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

USER root

# Instala o curl para utilitários / Healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 5001

ENV ASPNETCORE_URLS=http://+:5001
ENV ASPNETCORE_ENVIRONMENT=Production

# Copia os artefatos compilados do estágio 'build' para o estágio 'runtime'
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "Fiap.FCGames.Users.Api.dll"]