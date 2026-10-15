using Amazon.SecretsManager;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Fiap.FCGames.Users.CrossCutting.Services;
public static class AwsSecretsExtensions
{
     

    public static IServiceCollection AddAwsSecretsManager(this IServiceCollection services, IConfiguration configuration)
    {
        var awsRegion = configuration["AWS:Region"]
            ?? throw new InvalidOperationException("Configuração AWS:Region não encontrada. Defina a env var AWS__REGION.");
        var secretName = configuration["AWS:SecretName"]
            ?? throw new InvalidOperationException("Configuração AWS:SecretName não encontrada. Defina a env var AWS__SECRETNAME.");

        services.AddSingleton<IAmazonSecretsManager>(provider =>
        {
            var config = new AmazonSecretsManagerConfig { RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(awsRegion) };
            return new AmazonSecretsManagerClient(config);
        });

        services.AddSingleton<SecretsManagerService>(provider =>
        {
            var secretsManager = provider.GetRequiredService<IAmazonSecretsManager>();
            return new SecretsManagerService(secretsManager, secretName);
        });

        return services;
    }
}