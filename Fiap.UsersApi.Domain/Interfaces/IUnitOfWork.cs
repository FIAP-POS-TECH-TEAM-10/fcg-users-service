
namespace Fiap.Users.Domain.Interfaces
{
    public interface IUnitOfWork
    {
        IUsuarioRepository UsuarioRepository { get; }
        Task<int> CommitAsync(CancellationToken cancellationToken = default);
    }
}
