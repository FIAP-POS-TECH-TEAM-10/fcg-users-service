using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Commands.CriarUsuario;

public record CriarUsuarioCommand(
string Nome,
string Email,
string NomeUsuario,
string Senha) : IRequest<CriarUsuarioResponse>;
