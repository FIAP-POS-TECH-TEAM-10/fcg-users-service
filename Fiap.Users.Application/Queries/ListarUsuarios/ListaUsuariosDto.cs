using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json.Serialization;

namespace Fiap.Users.Application.Queries.ListarUsuarios
{
    public class ListaUsuariosDto
    {
        public Guid Id { get; set; }
        [JsonPropertyName("nome")]
        public required string Nome { get; set; }
        [JsonPropertyName("email")]
        public required string Email { get; set; }
        [JsonPropertyName("username")]
        public required string NomeUsuario { get; set; }
    }
}
