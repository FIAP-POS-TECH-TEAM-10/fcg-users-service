using Fiap.Users.Infra.DataProvider;
using Fiap.Users.Infra.Repositories;
using Fiap.Users.Infra.Services;
using Fiap.UsersApi.Domain.Services;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.IoC
{
    public static class RegisterDependencyInjectionExtensions
    {
        public static void RegisterDI(this IServiceCollection services)
        {
            // Repositories
            services.AddScoped<IUsuarioRepository, UsuarioRepository>();
           
            // Unit of Work
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            // Services
            services.AddScoped<ITokenService, TokenService>();
            services.AddScoped<IPasswordHasherService, PasswordHasherService>();
        }
    }
}
