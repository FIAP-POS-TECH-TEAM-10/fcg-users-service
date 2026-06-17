using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Application.Commands.Login
{
    public class UsuarioLogadoDto
    {
        public required string Usuario { get; set; }
        public required string Token { get; set; }
        public DateTime LoginExpiracao { get; set; }
    }
}
