using Fiap.Users.Domain.Interfaces;
using Fiap.UsersApi.Domain.Exceptions;
using Fiap.UsersApi.Domain.Services;
using MediatR;


namespace Fiap.Users.Application.Commands.Login
{
    public class LoginCommandHandler : IRequestHandler<LoginCommand, UsuarioLogadoDto>
    {
        private readonly ITokenService _tokenService;
        private readonly IUsuarioRepository _usuarioRepo;

        public LoginCommandHandler(ITokenService tokenService, IUsuarioRepository usuarioRepo)
        {
            _tokenService = tokenService;
            _usuarioRepo = usuarioRepo;
        }

        public async Task<UsuarioLogadoDto> Handle(LoginCommand request, CancellationToken cancellationToken)
        {
            DateTime tokenExpiracao = DateTime.Now.AddMinutes(30);

            var usuario = await _usuarioRepo.ObterAsync(request.Usuario, request.Senha);

            if (usuario is null)
                throw new LoginException("Usuário ou senha inválidos", 401);

            string role = usuario.IdTipoAcesso.ToString();

            var token = _tokenService.GerarToken(request.Usuario, role, tokenExpiracao);

            return new UsuarioLogadoDto
            {
                Token = token,
                Usuario = request.Usuario,
                LoginExpiracao = tokenExpiracao
            };
        }
    }
}
