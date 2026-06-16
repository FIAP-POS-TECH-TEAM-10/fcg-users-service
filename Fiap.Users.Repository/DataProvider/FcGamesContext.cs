using Fiap.UsersApi.Domain.Aggregates;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Reflection.Emit;
using System.Text;

namespace Fiap.Users.Infra.DataProvider
{
    public class FcGamesContexto : DbContext
    {
        public FcGamesContexto(DbContextOptions<FcGamesContexto> options) : base(options) { }

        public DbSet<Usuario> Usuarios { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.ApplyConfiguration(new UsuarioConfiguration());
        }
    }
}
