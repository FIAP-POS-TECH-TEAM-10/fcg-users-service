using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.DataProvider
{
    public class FcGamesContextoFactory : IDesignTimeDbContextFactory<FcGamesContexto>
    {
        public FcGamesContexto CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<FcGamesContexto>();
            optionsBuilder.UseSqlite("Data Source=fcgames.db");

            return new FcGamesContexto(optionsBuilder.Options);
        }
    }
}
