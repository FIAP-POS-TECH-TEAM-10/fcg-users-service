using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.UsersApi.Domain.Aggregates
{
    public class Usuario
    {
        public UsuarioId Id { get; set; }
        public required string Nome { get; set; }
        public required string Email { get; set; }
        public required string NomeUsuario { get; set; }
        public required string Senha { get; set; }
        public DateTime DataCadastro { get; set; }
        public int IdTipoAcesso { get; set; }
        public TipoAcesso TipoAcesso
        {
            get => (TipoAcesso)IdTipoAcesso;
            set => IdTipoAcesso = (int)value;
        }
    }
}
