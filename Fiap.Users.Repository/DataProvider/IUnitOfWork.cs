using Fiap.Users.Infra.Repositories;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.DataProvider
{
    public interface IUnitOfWork
    {
        IUsuarioRepository UsuarioRepository { get; }
        Task<int> CommitAsync(CancellationToken cancellationToken = default);
    }
}
