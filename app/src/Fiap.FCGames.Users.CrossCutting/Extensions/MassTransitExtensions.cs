using MassTransit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Fiap.FCGames.Users.CrossCutting.Extensions;

public static class MassTransitExtensions
{
    /// <summary>
    /// Registra o MassTransit escolhendo o transporte pela config, sem exigir mudança no
    /// código de aplicação (IPublishEndpoint/Publish/consumers continuam iguais):
    ///   Messaging:Provider = "Sqs"      -> Amazon SQS + SNS (ECS/AWS; precisa de Task Role)
    ///   RabbitMQ:Host      definido     -> RabbitMQ (local / docker-compose)
    ///   nenhum dos dois                 -> in-memory (satisfaz a DI; Publish() vira no-op)
    /// </summary>
    public static void AddMassTransitMessaging(this IServiceCollection services, IConfiguration configuration)
    {
        var provider = configuration["Messaging:Provider"];
        var rabbitHost = configuration["RabbitMQ:Host"];

        services.AddMassTransit(x =>
        {
            if (string.Equals(provider, "Sqs", StringComparison.OrdinalIgnoreCase))
            {
                // Amazon SQS (fila) + SNS (fan-out/pub-sub) — equivalente ao exchange do RabbitMQ.
                // Credenciais: cadeia padrão do AWS SDK (no ECS, vem da Task Role via
                // AWS_CONTAINER_CREDENTIALS_RELATIVE_URI, injetado automaticamente pelo agente).
                var region = configuration["AWS:Region"] ?? "sa-east-1";

                x.UsingAmazonSqs((context, cfg) =>
                {
                    cfg.Host(region, h => { });
                    cfg.ConfigureEndpoints(context);
                });
            }
            else if (!string.IsNullOrWhiteSpace(rabbitHost))
            {
                x.UsingRabbitMq((context, cfg) =>
                {
                    cfg.Host(
                        rabbitHost,
                        "/",
                        h =>
                        {
                            h.Username(configuration["RabbitMQ:Username"] ?? "guest");
                            h.Password(configuration["RabbitMQ:Password"] ?? "guest");
                        });

                    cfg.ConfigureEndpoints(context);
                });
            }
            else
            {
                // Sem broker configurado (ex.: deploy standalone sem RabbitMQ nem SQS habilitado).
                x.UsingInMemory((context, cfg) => cfg.ConfigureEndpoints(context));
            }
        });
    }
}
