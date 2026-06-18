using Fiap.UsersApi.Domain.Services;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;

namespace Fiap.Users.Infra.Services
{
    public class PasswordHasherService : IPasswordHasherService
    {
        private const int Iterations = 100000;
        private const int SaltSize = 16;
        private const int KeySize = 32;
        public string GerarHash(string senha)
        {
            var salt = RandomNumberGenerator.GetBytes(SaltSize);
            var key = Rfc2898DeriveBytes.Pbkdf2(senha, salt, Iterations, HashAlgorithmName.SHA256, KeySize);

            return $"PBKDF2|SHA256|{Iterations}|{Convert.ToBase64String(salt)}|{Convert.ToBase64String(key)}";
        }

        public bool Verificar(string senhaTexto, string senhaHash)
        {
            if (string.IsNullOrWhiteSpace(senhaHash))
                return false;

            var partes = senhaHash.Split('|');

            if (partes.Length == 5 && partes[0] == "PBKDF2")
            {
                var algoritmo = partes[1] == "SHA1" ? HashAlgorithmName.SHA1 : HashAlgorithmName.SHA256;
                var iterations = int.Parse(partes[2]);
                var salt = Convert.FromBase64String(partes[3]);
                var hashEsperado = Convert.FromBase64String(partes[4]);
                var hashAtual = Rfc2898DeriveBytes.Pbkdf2(senhaTexto, salt, iterations, algoritmo, hashEsperado.Length);

                return CryptographicOperations.FixedTimeEquals(hashAtual, hashEsperado);
            }

            var senhaBytes = Encoding.UTF8.GetBytes(senhaTexto);
            var hashBytes = Encoding.UTF8.GetBytes(senhaHash);
            return CryptographicOperations.FixedTimeEquals(senhaBytes, hashBytes);
        }
    }
}
