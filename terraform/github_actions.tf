# Identity for the deploy workflow in .github/workflows/deploy.yml.
#
# GitHub mints a short-lived OIDC token per workflow run and AWS exchanges it
# for temporary credentials, so unlike the spc-mod key in iam.tf there is no
# long-lived secret stored in the repo or needing rotation.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS no longer validates this thumbprint for the GitHub OIDC endpoint (it
  # trusts the host's public CA chain instead), but the API still rejects an
  # empty list, so the historical value stays here as a placeholder.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scoped to main, so only pushes/schedules/dispatches on the default
    # branch can assume the role. A pull_request run carries a
    # `pull_request` sub claim instead and is rejected here - the workflow
    # skips its deploy steps on PRs, but this is what actually enforces it.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${local.site_fqdn}-github-actions-deploy"
  description        = "Deploys the ${local.site_fqdn} static site from GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Same read/write grant the human SeattlePhotoClub group gets (see iam.tf) -
# `hugo deploy` needs to list the bucket and put/delete objects in it.
resource "aws_iam_role_policy_attachment" "github_actions_site_bucket_rw" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.site_bucket_rw.arn
}

# `hugo deploy` invalidates the CDN after uploading (invalidateCDN defaults
# to true, targeting the cloudFrontDistributionID set in hugo.yaml).
data "aws_iam_policy_document" "cloudfront_invalidation" {
  statement {
    sid       = "CreateInvalidation"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_policy" "cloudfront_invalidation" {
  name        = "${local.site_fqdn}-cloudfront-invalidation"
  description = "Create cache invalidations on the ${local.site_fqdn} distribution"
  policy      = data.aws_iam_policy_document.cloudfront_invalidation.json
}

resource "aws_iam_role_policy_attachment" "github_actions_cloudfront_invalidation" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.cloudfront_invalidation.arn
}
