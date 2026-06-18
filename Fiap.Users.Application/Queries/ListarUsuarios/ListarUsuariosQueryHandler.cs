using Fiap.Users.Domain.Interfaces;
using MediatR;

namespace Fiap.Users.Application.Queries.ListarUsuarios
{
    public class ListarUsuariosQueryHandler:IRequestHandler<ListarUsuariosQuery, IEnumerable<ListaUsuariosDto>>
    {
        private readonly IUsuarioRepository _usuarioRepository;

        public ListarUsuariosQueryHandler(IUsuarioRepository usuarioRepository)
        {
            _usuarioRepository = usuarioRepository;
        }

        public async Task<IEnumerable<ListaUsuariosDto>> Handle(ListarUsuariosQuery request, CancellationToken cancellationToken)
        {
            var usuarios = await _usuarioRepository.ObterTodosAsync();
            return usuarios.Select(u => new ListaUsuariosDto
            {
                Id = u.Id.Value,
                Nome = u.Nome,
                Email = u.Email,
                NomeUsuario = u.NomeUsuario
            }).ToList();
        }
    }
}
