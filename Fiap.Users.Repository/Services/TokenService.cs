using Fiap.UsersApi.Domain.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Fiap.Users.Infra.Services
{
    public class TokenService : ITokenService
    {
        private readonly string _jwtKey;
        private readonly string _jwtIssuer;

        public TokenService(IConfiguration configuration)
        {
            _jwtKey = configuration["Jwt:Key"]
                ?? throw new InvalidOperationException("Configuração Jwt:Key não encontrada.");
            _jwtIssuer = configuration["Jwt:Issuer"]
                ?? throw new InvalidOperationException("Configuração Jwt:Issuer não encontrada.");
        }
        public string GerarToken(string usuario, string role, DateTime loginExpiracao)
        {
            var claim = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, usuario),
                new Claim(ClaimTypes.Role, role),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _jwtIssuer,
                claims: claim,
                signingCredentials: creds,
                expires: loginExpiracao
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public bool ValidarToken(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
                return false;

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.UTF8.GetBytes(_jwtKey);

            try
            {
                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _jwtIssuer,
                    ValidateAudience = false,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                }, out _);

                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}
