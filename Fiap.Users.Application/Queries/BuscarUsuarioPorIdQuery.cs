using MediatR;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Queries
{
    public record BuscarUsuarioPorIdQuery(Guid Id) : IRequest<DetalhesUsuarioDto>
    {
    }
}
