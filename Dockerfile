FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

ARG NUGET_AUTH_TOKEN
ENV NUGET_AUTH_TOKEN=$NUGET_AUTH_TOKEN

COPY nuget.config .
COPY app/src/ app/src/

WORKDIR /src/app/src
RUN dotnet restore Fiap.FCGames.Users.Api/Fiap.FCGames.Users.Api.csproj

RUN dotnet publish Fiap.FCGames.Users.Api/Fiap.FCGames.Users.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# curl é necessário para o HEALTHCHECK do docker-compose / k8s (não vem na imagem aspnet).
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 5001

ENV ASPNETCORE_URLS=http://+:5001
ENV ASPNETCORE_ENVIRONMENT=Production

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "Fiap.FCGames.Users.Api.dll"]
