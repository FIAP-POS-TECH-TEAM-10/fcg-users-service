using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;

namespace Fiap.FCGames.Users.CrossCutting.Services;

  

    public class SecretsManagerService 
    {
        private readonly IAmazonSecretsManager _secretsManager;
        private readonly string _secretName;

        public SecretsManagerService(IAmazonSecretsManager secretsManager, string secretName)
        {
            _secretsManager = secretsManager;
            _secretName = secretName;
        }

        public async Task<string> GetSecretValueAsync()
        {
            var request = new GetSecretValueRequest
            {
                SecretId = _secretName
            };

            var response = await _secretsManager.GetSecretValueAsync(request);
            return response.SecretString;
        }
    }
}
public class AwsSecretsExtensions
{
     private readonly IAmazonSecretsManager _secretsManager;
    private const string SecretName = "prod/fiap-proj/secrets";
    public static void AddAwsSecretsManager(this IServiceCollection services, IConfiguration configuration)
    {
        var awsRegion = configuration["AWS:Region"]
            ?? throw new InvalidOperationException("Configuração AWS:Region não encontrada. Defina a env var AWS__REGION.");
        var secretName = configuration["AWS:SecretName"]
            ?? throw new InvalidOperationException("Configuração AWS:SecretName não encontrada. Defina a env var AWS__SECRETNAME.");

        services.AddAWSService<IAmazonSecretsManager>(options =>
        {
            options.Region = Amazon.RegionEndpoint.GetBySystemName(awsRegion);
        });

        services.AddSingleton<ISecretsManagerService>(provider =>
        {
            var secretsManager = provider.GetRequiredService<IAmazonSecretsManager>();
            return new SecretsManagerService(secretsManager, secretName);
        });
    }