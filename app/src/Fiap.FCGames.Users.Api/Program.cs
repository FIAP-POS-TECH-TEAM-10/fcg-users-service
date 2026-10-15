using Fiap.FCGames.Users.CrossCutting.Extensions;
using Fiap.FCGames.Users.CrossCutting.Middleware;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Serilog;
using Prometheus;
using Fiap.FCGames.Users.Infra.DataProvider.Contexto;
using Fiap.FCGames.Users.CrossCutting.Services;


var builder = WebApplication.CreateBuilder(args);
// Adiciona suporte a AWS Secrets Manager
builder.Services.AddAwsSecretsManager(builder.Configuration);

builder.Services.AddControllers();
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
    options.SuppressModelStateInvalidFilter = true);
builder.Services.AddOpenApi();

builder.Services.RegisterDI();
builder.Services.AddMediatRConfiguration();
builder.Services.RegisterSwaggerGenerator();
builder.Services.AddAutenticacaoApi(builder.Configuration);
builder.Services.AddAutorizacaoApi();
builder.Services.AddContextDatabase(builder.Configuration);
builder.Services.AddMassTransitMessaging(builder.Configuration);
builder.Services.AddHealthChecks();

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .CreateLogger();

builder.Host.UseSerilog();

var app = builder.Build();

if (!app.Environment.IsEnvironment("Testing"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<FcGamesContexto>();
    db.Database.Migrate();
    await SeedAdminAsync(scope.ServiceProvider);
}

//TESTA A CONEXÃO COM O SECRETS MANAGER DA AWS
try
{
    var secretsService =
        app.Services.GetRequiredService<SecretsManagerService>();

    var secret = await secretsService.GetSecretAsync();

    if (string.IsNullOrWhiteSpace(secret))
    {
        throw new InvalidOperationException("O segredo está vazio.");
    }

    app.Logger.LogInformation(
        "Sucesso! O segredo foi recuperado da AWS.");
}
catch (Exception ex)
{
    app.Logger.LogError(ex, "Falha ao acessar o segredo da AWS.");
    throw;
}

app.UseCorrelationId();

app.RegisterSwagger();
app.MapOpenApi();

// if (app.Environment.IsDevelopment())
// {
//     //app.RegisterSwagger();
//     ///app.MapOpenApi();
//     //app.RegisterScalar();
// }

// Middleware para métricas HTTP (latência, status code, etc.)
app.UseRouting();
app.UseHttpMetrics();

// Endpoint padrão /metrics
app.MapMetrics();

app.UseErrorHandlingMiddleware();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});

Log.Information("FCGames UsersAPI iniciada em {Urls}", string.Join(", ", app.Urls.DefaultIfEmpty("http://localhost:5001")));
Log.Information("UsersAPI pronta — imagem publicada pelo pipeline CI/CD (Fase 4)");

app.Run();

static async Task SeedAdminAsync(IServiceProvider services)
{
    var db = services.GetRequiredService<FcGamesContexto>();
    var hasAdmin = await db.Usuarios.AnyAsync(u => u.IdTipoAcesso == 1);
    if (hasAdmin) return;

    var passwordHasher = services.GetRequiredService<Fiap.FCGames.Users.Domain.Services.IPasswordHasherService>();
    var admin = new Fiap.FCGames.Users.Domain.Aggregates.Usuario
    {
        Id = Fiap.FCGames.Users.Domain.Aggregates.UsuarioId.New(),
        Nome = "Administrador",
        Email = "admin@fcgames.com",
        SenhaHash = passwordHasher.GerarHash("Admin@123"),
        TipoAcesso = Fiap.FCGames.Users.Domain.Aggregates.TipoAcesso.Admin,
        CriadoEm = DateTime.UtcNow
    };

    db.Usuarios.Add(admin);
    await db.SaveChangesAsync();

    var logger = services.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("Seed: usuário Admin criado (admin@fcgames.com / Admin@123)");
}
