using MassTransit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Fiap.FCGames.Users.CrossCutting.Extensions;

public static class MassTransitExtensions
{
    public static void AddMassTransitRabbitMq(this IServiceCollection services, IConfiguration configuration)
    {
        var rabbitHost = configuration["RabbitMQ:Host"];

        services.AddMassTransit(x =>
        {
            if (string.IsNullOrWhiteSpace(rabbitHost))
            {
                // Sem broker configurado (deploy standalone do UsersAPI, ex.: ECS na AWS sem RabbitMQ).
                // Usa o transporte in-memory só para satisfazer IPublishEndpoint na DI;
                // os Publish() viram no-op (o handler já trata falha de publicação).
                x.UsingInMemory((context, cfg) => cfg.ConfigureEndpoints(context));
            }
            else
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
        });
    }
}
