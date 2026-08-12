# Static site on S3 + CloudFront + Route 53

Creates a private S3 bucket for content, a CloudFront distribution in front
of it (via Origin Access Control), an ACM certificate for SSL, and a new
Route 53 hosted zone with records pointing the domain at CloudFront.

All Terraform config lives in this `terraform/` directory; run all commands
below from here.

## Usage

1. Copy the example vars and fill in your domain:

   ```
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Init and apply:

   ```
   terraform init
   terraform apply
   ```

3. This creates a **new** Route 53 hosted zone. After apply, point your
   domain registrar's nameservers at the values in the `route53_name_servers`
   output. DNS validation for the ACM certificate happens automatically
   against this same zone, but the zone itself won't resolve publicly until
   the registrar's NS records are updated.

4. Terraform doesn't manage page content. Normally `.github/workflows/deploy.yml`
   builds and uploads it (see below), but to push content by hand:

   ```
   hugo && hugo deploy
   ```

   `hugo deploy` syncs `public/` to the bucket and invalidates CloudFront,
   using the `deployment` block in `hugo.yaml`. Note that this needs a Hugo
   binary built with the `withdeploy` tag - the Homebrew build has it, the
   stock GitHub release binaries do not.

## GitHub Actions deploys

`github_actions.tf` creates an OIDC provider and an IAM role that the deploy
workflow assumes. No access key is involved: GitHub mints a short-lived token
per run and AWS exchanges it for temporary credentials. The role's trust
policy only accepts runs on `main` of the repo named in
`var.github_repository`.

After the first `terraform apply`, store the role ARN as a repository secret
so the workflow can find it:

```
gh secret set AWS_DEPLOY_ROLE_ARN \
  --body "$(terraform output -raw github_actions_deploy_role_arn)"
```

If the AWS account already has a GitHub OIDC provider, the apply will fail
with `EntityAlreadyExists`. Import the existing one instead of creating a
second:

```
terraform import aws_iam_openid_connect_provider.github \
  arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
```

## Notes

- `site_subdomain` defaults to `""` (serves from the apex domain). Set it to
  `"www"` in `terraform.tfvars` to serve from `www.<domain_name>` instead.
- The S3 bucket is fully private; CloudFront reaches it via Origin Access
  Control (OAC), not a public bucket policy or website endpoint.
- The ACM certificate is requested in `us-east-1` regardless of `aws_region`,
  since CloudFront requires that.
- 404s are rewritten to `error_document` with a 200 status, which is
  convenient for single-page apps. Remove the `custom_error_response` block
  in `cloudfront.tf` if you don't want that behavior.
