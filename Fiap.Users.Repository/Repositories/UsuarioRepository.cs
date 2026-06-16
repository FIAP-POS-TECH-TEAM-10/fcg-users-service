using Fiap.Users.Infra.DataProvider;
using Fiap.UsersApi.Domain.Aggregates;
using Fiap.UsersApi.Domain.Services;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.Repositories
{
    public class UsuarioRepository : GenericRepository<Usuario>, IUsuarioRepository
    {
        private readonly IPasswordHasherService _passwordHasherService;

        public UsuarioRepository(FcGamesContexto context, IPasswordHasherService passwordHasherService) : base(context)
        {
            _passwordHasherService = passwordHasherService;
        }

        public void Adicionar(Usuario usuario) => Create(usuario);

        public void Atualizar(Usuario usuario) => Update(usuario);

        public async Task<IEnumerable<Usuario>> ObterTodosAsync()
        {
            return await _dbSet.AsNoTracking()
                .ToListAsync();
        }

        public async Task<Usuario?> ObterAsync(string usuario, string senha)
        {
            var usuarioDb = await _dbSet.AsNoTracking()
                .Where(x => x.NomeUsuario.ToLower().Equals(usuario.ToLower()))
                .FirstOrDefaultAsync();

            if (usuarioDb is null)
                return null;

            return _passwordHasherService.Verificar(senha, usuarioDb.Senha)
                ? usuarioDb
                : null;
        }

        public async Task<Usuario?> ObterPorIdAsync(UsuarioId id)
        {
            return await _dbSet.AsNoTracking()
                .Where(x => x.Id == id)
                .FirstOrDefaultAsync();
        }

        public Task<bool> ExisteEmailAsync(string email)
            => _dbSet.AsNoTracking().AnyAsync(x => x.Email.ToLower() == email.ToLower());

        public Task<bool> ExisteNomeUsuarioAsync(string nomeUsuario)
            => _dbSet.AsNoTracking().AnyAsync(x => x.NomeUsuario.ToLower() == nomeUsuario.ToLower());
    }
}
