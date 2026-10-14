using Fiap.FCGames.Users.Infra.DataProvider.Contexto;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Fiap.FCGames.Users.CrossCutting.Extensions;

public static class RegisterContextDatabaseExtensions
{
    public static void AddContextDatabase(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration["DB_CONNECTION"]
            ?? configuration.GetConnectionString("DefaultConnection");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "A configuração DB_CONNECTION não foi definida no AWS Secrets Manager ou na configuração local.");
        }

        services.AddDbContext<FcGamesContexto>(options =>
            options.UseSqlite(connectionString));
    }
}
