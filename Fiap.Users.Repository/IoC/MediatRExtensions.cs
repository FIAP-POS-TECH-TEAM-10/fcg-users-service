using Microsoft.Extensions.DependencyInjection;
using MediatR;

namespace Fiap.Users.Infra.IoC
{
    public static class MediatRExtensions
    {
        public static IServiceCollection AddMediatRConfiguration(this IServiceCollection services)
        {
            var appAssembly = typeof(IAssemblyMarker).Assembly;

            services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(appAssembly));

            return services;
        }
    }
}
