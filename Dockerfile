FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY nuget.config .
COPY app/src/ app/src/

WORKDIR /src/app/src

# Utiliza o secret montado dinamicamente para autenticar o restore sem expor o token
RUN --mount=type=secret,id=GITHUB_TOKEN \
    export NUGET_AUTH_TOKEN=$(cat /run/secrets/GITHUB_TOKEN) && \
    dotnet restore Fiap.FCGames.Users.Api/Fiap.FCGames.Users.Api.csproj    

# Compila e publica a aplicação
RUN --mount=type=secret,id=GITHUB_TOKEN \
    export NUGET_AUTH_TOKEN=$(cat /run/secrets/GITHUB_TOKEN) && \
    dotnet publish Fiap.FCGames.Users.Api/Fiap.FCGames.Users.Api.csproj -c Release -o /app/publish /p:UseAppHost=false    

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# # curl é necessário para o HEALTHCHECK do docker-compose / k8s (não vem na imagem aspnet).
# RUN apt-get update && apt-get install -y --no-install-recommends curl \
#     && rm -rf /var/lib/apt/lists/*

# Instala bibliotecas nativas de internacionalizacao e suporte a timezone
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    icu-devtools \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*    

EXPOSE 5001

# Garante que a API aceita requisições vindas do IP público da EC2
ENV ASPNETCORE_URLS=http://+:5001
ENV ASPNETCORE_ENVIRONMENT=Production

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "Fiap.FCGames.Users.Api.dll"]
