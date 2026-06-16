using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.UsersApi.Domain.Services
{
    public interface IPasswordHasherService
    {
        string GerarHash(string senha);
        bool Verificar(string senhaTexto, string senhaHash);
    }
}
