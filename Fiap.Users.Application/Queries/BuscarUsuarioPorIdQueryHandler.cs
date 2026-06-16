using Fiap.Users.Infra.Repositories;
using Fiap.UsersApi.Domain.Aggregates;
using Fiap.UsersApi.Domain.Exceptions;
using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Queries
{
    public class BuscarUsuarioPorIdQueryHandler : IRequestHandler<BuscarUsuarioPorIdQuery, DetalhesUsuarioDto>
    {
        private readonly IUsuarioRepository _usuarioRepo;
        public async Task<DetalhesUsuarioDto> Handle(BuscarUsuarioPorIdQuery request, CancellationToken cancellationToken)
        {
            var usuario = await _usuarioRepo.ObterPorIdAsync(new UsuarioId(request.Id));

            if (usuario == null)
                throw new NotFoundException("Usuário não encontrado.");

            return new DetalhesUsuarioDto
            {
                Id = usuario.Id.Value,
                Nome = usuario.Nome,
                Email = usuario.Email,
                NomeUsuario = usuario.NomeUsuario,
                DataCadastro = usuario.DataCadastro,
                TipoAcesso = usuario.TipoAcesso
            };
        }
    }
}
