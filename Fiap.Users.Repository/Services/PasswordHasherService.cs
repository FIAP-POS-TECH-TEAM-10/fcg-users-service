using Fiap.UsersApi.Domain.Services;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.Services
{
    public class PasswordHasherService : IPasswordHasherService
    {
        public string GerarHash(string senha)
        {
            throw new NotImplementedException();
        }

        public bool Verificar(string senhaTexto, string senhaHash)
        {
            throw new NotImplementedException();
        }
    }
}
