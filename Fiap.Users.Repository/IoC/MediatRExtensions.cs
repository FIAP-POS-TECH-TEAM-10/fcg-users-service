using Microsoft.Extensions.DependencyInjection;
using Fiap.Users.Application;

namespace Fiap.Users.Infra.IoC
{
    public static class MediatRExtensions
    {
        public static IServiceCollection AddMediatRConfiguration(this IServiceCollection services)
        {
            var appAssembly = typeof(IAssemblyMarker).Assembly;

            services.AddMediatR(cfg => cfg.RegisterServicesFromAssemblies(appAssembly));

            return services;
        }
    }
}
