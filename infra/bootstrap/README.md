# infra/bootstrap

Recursos que o Terraform principal (`../`) assume que **já existem** numa conta AWS.
Roda com **state local** e apenas **uma vez por conta**.

## O que cria

| Recurso | Serve para |
|---|---|
| Bucket S3 `fcg-users-service-tfstate-<account>-<region>` (versionado, criptografado, privado) | backend remoto do `../` |
| Tabela DynamoDB `fcg-users-service-tflocks` | lock de state do `../` |
| OIDC provider `token.actions.githubusercontent.com` | GitHub Actions autenticar sem access key |
| IAM Role `GitHubActions-ECS-Deploy-Role` (PowerUserAccess + IAM escopado a `fcg-users-service-*`) | assumida por `.github/workflows/*.yml` |

## Uso

```bash
cd infra/bootstrap
terraform init
terraform apply
```

Anote os outputs:

```bash
terraform output
# tfstate_bucket  = "fcg-users-service-tfstate-123456789012-sa-east-1"
# tflock_table    = "fcg-users-service-tflocks"
# deploy_role_arn = "arn:aws:iam::123456789012:role/GitHubActions-ECS-Deploy-Role"
# account_id      = "123456789012"
```

Depois, no Terraform principal, ajuste `../main.tf` (bloco `backend "s3"`) com
`tfstate_bucket` e `tflock_table`, e os 3 workflows + `.aws/task-definition.json`
com `account_id` / `deploy_role_arn`.

## Se o OIDC provider já existir na conta

`Error: EntityAlreadyExists` no `aws_iam_openid_connect_provider.github`. Importe:

```bash
terraform import aws_iam_openid_connect_provider.github \
  arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
terraform apply
```

## Não commitar

O `terraform.tfstate` desta pasta fica local (já coberto pelo `.gitignore` do repo).
Guarde-o — é o que permite dar `destroy`/`update` no bootstrap depois.
