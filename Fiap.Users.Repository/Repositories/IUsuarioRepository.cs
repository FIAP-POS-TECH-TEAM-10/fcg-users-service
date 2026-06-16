using Fiap.UsersApi.Domain.Aggregates;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.Repositories
{
    public interface IUsuarioRepository
    {
        void Adicionar(Usuario usuario);
        Task<Usuario?> ObterAsync(string usuario, string senha);
        Task<IEnumerable<Usuario>> ObterTodosAsync();
        Task<Usuario?> ObterPorIdAsync(UsuarioId id);
        Task<bool> ExisteEmailAsync(string email);
        Task<bool> ExisteNomeUsuarioAsync(string nomeUsuario);
        void Atualizar(Usuario usuario);
    }
}
