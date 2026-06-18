using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Queries.ListarUsuarios;

public record ListarUsuariosQuery : IRequest<IEnumerable<ListaUsuariosDto>>;
