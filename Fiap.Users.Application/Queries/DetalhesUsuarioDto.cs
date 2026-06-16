using Fiap.UsersApi.Domain.Aggregates;

namespace Fiap.Users.Application.Queries
{
    public class DetalhesUsuarioDto
    {
        public Guid Id { get; set; }
        public required string Nome { get; set; }
        public required string Email { get; set; }
        public required string NomeUsuario { get; set; }
        public DateTime? DataCadastro { get; set; }
        public TipoAcesso TipoAcesso { get; set; }
    }
}