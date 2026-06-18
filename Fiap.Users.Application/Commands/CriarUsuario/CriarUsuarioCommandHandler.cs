using Fiap.Users.Domain.Interfaces;
using Fiap.UsersApi.Domain.Aggregates;
using Fiap.UsersApi.Domain.Services;
using MediatR;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Fiap.Users.Application.Commands.CriarUsuario;

public class CriarUsuarioCommandHandler : IRequestHandler<CriarUsuarioCommand, CriarUsuarioResponse>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasherService _passwordHasherService;

    public CriarUsuarioCommandHandler(
        IUnitOfWork unitOfWork,
        IPasswordHasherService passwordHasherService)
    {
        _unitOfWork = unitOfWork;
        _passwordHasherService = passwordHasherService;
    }

    public async Task<CriarUsuarioResponse> Handle(
        CriarUsuarioCommand request,
        CancellationToken cancellationToken)
    {
        var emailExiste = await _unitOfWork.UsuarioRepository.ExisteEmailAsync(request.Email);
        if (emailExiste)
            throw new ValidationException("Já existe um usuário com o e-mail informado.");

        var nomeUsuarioExiste = await _unitOfWork.UsuarioRepository.ExisteNomeUsuarioAsync(request.NomeUsuario);
        if (nomeUsuarioExiste)
            throw new ValidationException("Já existe um usuário com o nome de usuário informado.");

        var usuario = new Usuario
        {
            Id = UsuarioId.New(),
            Nome = request.Nome,
            Email = request.Email,
            NomeUsuario = request.NomeUsuario.ToLower(),
            Senha = _passwordHasherService.GerarHash(request.Senha),
            DataCadastro = DateTime.Now,
            TipoAcesso = TipoAcesso.User
        };
        _unitOfWork.UsuarioRepository.Adicionar(usuario);

        
        await _unitOfWork.CommitAsync(cancellationToken);

        return new CriarUsuarioResponse
        {
            Id = usuario.Id.Value,
            Nome = usuario.Nome,
            Email = usuario.Email,
        };
    }
}