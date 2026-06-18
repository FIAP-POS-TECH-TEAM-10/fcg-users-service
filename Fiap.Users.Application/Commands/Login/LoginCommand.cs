using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Commands.Login;

public record LoginCommand(string Usuario, string Senha) : IRequest<UsuarioLogadoDto>;

