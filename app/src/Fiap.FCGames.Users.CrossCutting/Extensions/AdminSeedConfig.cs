using Microsoft.Extensions.Configuration;

namespace Fiap.FCGames.Users.CrossCutting.Extensions;

public static class AdminSeedConfig
{
    public static string RequirePassword(IConfiguration configuration)
    {
        var senha = configuration["Admin:Password"];

        if (string.IsNullOrWhiteSpace(senha))
            throw new InvalidOperationException("Configuração Admin:Password não encontrada. Defina a env var ADMIN__PASSWORD.");

        return senha;
    }
}
