using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Commands.AtualizarUsuario
{
    public record AtualizarUsuarioCommand(
     Guid Id,
     string Nome,
     string Email,
     string Senha,
     string NomeUsuario) : IRequest<AtualizarUsuarioResponse>;
}
