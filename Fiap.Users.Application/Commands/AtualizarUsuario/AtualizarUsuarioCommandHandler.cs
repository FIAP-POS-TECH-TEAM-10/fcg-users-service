using Fiap.Users.Domain.Interfaces;
using Fiap.UsersApi.Domain.Aggregates;
using Fiap.UsersApi.Domain.Exceptions;
using Fiap.UsersApi.Domain.Services;
using MediatR;

namespace Fiap.Users.Application.Commands.AtualizarUsuario
{
    public class AtualizarUsuarioCommandHandler : IRequestHandler<AtualizarUsuarioCommand, AtualizarUsuarioResponse>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IPasswordHasherService _passwordHasherService;

        public AtualizarUsuarioCommandHandler(
            IUnitOfWork unitOfWork,
            IPasswordHasherService passwordHasherService)
        {
            _unitOfWork = unitOfWork;
            _passwordHasherService = passwordHasherService;
        }

        public async Task<AtualizarUsuarioResponse> Handle(AtualizarUsuarioCommand request, CancellationToken cancellationToken)
        {
            var usuario = await _unitOfWork.UsuarioRepository.ObterPorIdAsync(new UsuarioId(request.Id));

            if (usuario is null)
                throw new NotFoundException("Usuário não encontrado.");

            usuario.Nome = request.Nome;
            usuario.Email = request.Email;
            usuario.Senha = _passwordHasherService.GerarHash(request.Senha);
            usuario.NomeUsuario = request.NomeUsuario.ToLower();

            _unitOfWork.UsuarioRepository.Atualizar(usuario);

            await _unitOfWork.CommitAsync(cancellationToken);

            return new AtualizarUsuarioResponse
            {
                Id = usuario.Id.Value,
                Nome = usuario.Nome,
                Email = usuario.Email
            };
        }
    }
}
