using FCGames.IntegrationEvents;
using Fiap.FCGames.Users.Domain.Aggregates;
using Fiap.FCGames.Users.Domain.Exceptions;
using Fiap.FCGames.Users.Domain.Interfaces;
using Fiap.FCGames.Users.Domain.Services;
using MassTransit;
using MediatR;
using Microsoft.Extensions.Logging;

namespace Fiap.FCGames.Users.Application.Commands.CriarUsuario;

public class CriarUsuarioCommandHandler : IRequestHandler<CriarUsuarioCommand, CriarUsuarioResponse>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasherService _passwordHasher;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<CriarUsuarioCommandHandler> _logger;

    public CriarUsuarioCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasherService passwordHasher,
        IPublishEndpoint publishEndpoint,
        ILogger<CriarUsuarioCommandHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<CriarUsuarioResponse> Handle(CriarUsuarioCommand request, CancellationToken cancellationToken)
    {
        var emailExiste = await _unitOfWork.UsuarioRepository.ExisteEmailAsync(request.Email);
        if (emailExiste)
            throw new BusinessException("Já existe um usuário com o e-mail informado.");

        var usuario = new Usuario
        {
            Id = UsuarioId.New(),
            Nome = request.Nome,
            Email = request.Email.ToLower(),
            SenhaHash = _passwordHasher.GerarHash(request.Senha),
            TipoAcesso = TipoAcesso.Standard,
            CriadoEm = DateTime.UtcNow
        };

        _unitOfWork.UsuarioRepository.Adicionar(usuario);

        await _publishEndpoint.Publish(new UsuarioCriadoEvento(
            UsuarioId: usuario.Id.Value,
            Nome: usuario.Nome,
            Email: usuario.Email,
            CriadoEmUtc: usuario.CriadoEm,
            CorrelationId: Guid.NewGuid()),
            cancellationToken);

        await _unitOfWork.CommitAsync(cancellationToken);

        return new CriarUsuarioResponse
        {
            Id = usuario.Id.Value,
            Nome = usuario.Nome,
            Email = usuario.Email
        };
    }
}
