using Fiap.FCGames.Users.Domain.Aggregates;
using Fiap.FCGames.Users.Infra.DataProvider.EntityConfigurations;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace Fiap.FCGames.Users.Infra.DataProvider.Contexto;

public class FcGamesContexto : DbContext
{
    public FcGamesContexto(DbContextOptions<FcGamesContexto> options) : base(options) { }

    public DbSet<Usuario> Usuarios { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new UsuarioConfiguration());

        modelBuilder.AddInboxStateEntity();
        modelBuilder.AddOutboxMessageEntity();
        modelBuilder.AddOutboxStateEntity();
    }
}
