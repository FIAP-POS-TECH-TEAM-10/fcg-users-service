using Fiap.FCGames.Users.CrossCutting.Extensions;
using Microsoft.Extensions.Configuration;

namespace Fiap.FCGames.Users.Tests;

public class AdminSeedConfigTests
{
    private static IConfiguration Config(string? senha)
    {
        var dados = new Dictionary<string, string?>();
        if (senha is not null) dados["Admin:Password"] = senha;
        return new ConfigurationBuilder().AddInMemoryCollection(dados).Build();
    }

    [Fact]
    public void RequirePassword_devolve_o_valor_sem_alterar()
    {
        const string senha = "a\"b$c!";

        Assert.Equal(senha, AdminSeedConfig.RequirePassword(Config(senha)));
    }

    [Fact]
    public void RequirePassword_lanca_quando_ausente()
    {
        var ex = Assert.Throws<InvalidOperationException>(() => AdminSeedConfig.RequirePassword(Config(null)));

        Assert.Contains("ADMIN__PASSWORD", ex.Message);
    }

    [Fact]
    public void RequirePassword_lanca_quando_so_espacos()
    {
        var ex = Assert.Throws<InvalidOperationException>(() => AdminSeedConfig.RequirePassword(Config("   ")));

        Assert.Contains("ADMIN__PASSWORD", ex.Message);
    }
}
