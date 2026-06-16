using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.UsersApi.Domain.Aggregates
{
    public record struct UsuarioId(Guid Value)
    {
        public static UsuarioId New() => new(Guid.NewGuid());
        public override readonly string ToString() => Value.ToString();
    }
}
