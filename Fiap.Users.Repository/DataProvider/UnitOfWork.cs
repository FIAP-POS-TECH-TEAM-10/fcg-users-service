using Fiap.Users.Domain.Interfaces;
using Fiap.Users.Infra.Repositories;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.DataProvider
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly FcGamesContexto _context;
        public IUsuarioRepository UsuarioRepository { get; }
       
        public UnitOfWork(
            FcGamesContexto context,
            IUsuarioRepository usuarioRepository)
           {
            _context = context;
            UsuarioRepository = usuarioRepository;
           }

        public Task<int> CommitAsync(CancellationToken cancellationToken = default)
            => _context.SaveChangesAsync(cancellationToken);
    }

}
