using Fiap.UsersApi.Domain.Aggregates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Text;

namespace Fiap.Users.Infra.DataProvider
{
    public class UsuarioConfiguration : IEntityTypeConfiguration<Usuario>
    {
        public void Configure(EntityTypeBuilder<Usuario> builder)
        {
            builder.ToTable("usuario");

            builder.HasKey(e => e.Id)
                .HasName("PRIMARY");

            builder.Property(e => e.Id)
                .HasColumnName("id_usuario")
                .HasConversion(id => id.Value, value => new UsuarioId(value))
                .ValueGeneratedNever();

            builder.Property(e => e.Nome)
                .HasColumnName("nome")
                .IsRequired()
                .HasMaxLength(150);

            builder.Property(e => e.Email)
                .HasColumnName("email")
                .IsRequired()
                .HasMaxLength(200);

            builder.Property(e => e.NomeUsuario)
                .HasColumnName("nome_usuario")
                .IsRequired()
                .HasMaxLength(50);

            builder.Property(e => e.Senha)
                .HasColumnName("senha")
                .IsRequired()
                .HasMaxLength(255);

            builder.Property(e => e.DataCadastro)
                .HasColumnName("data_cadastro")
                .IsRequired();

            builder.Property(e => e.IdTipoAcesso)
                .HasColumnName("id_tipo_acesso")
                .IsRequired();

            builder.Ignore(e => e.TipoAcesso);

           
        }
    }
}
