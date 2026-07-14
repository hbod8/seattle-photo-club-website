# spc-mod and the SeattlePhotoClub group already existed in AWS before this
# was written to Terraform; import blocks below bring them under management
# without recreating them.

resource "aws_iam_user" "spc_mod" {
  name = "spc-mod"
}

resource "aws_iam_group" "seattle_photo_club" {
  name = "SeattlePhotoClub"
}

resource "aws_iam_user_group_membership" "spc_mod" {
  user   = aws_iam_user.spc_mod.name
  groups = [aws_iam_group.seattle_photo_club.name]
}

# No pgp_key set, so Terraform generates a random password and stores it in
# plaintext in state - the spc_mod_initial_password output is the one-time
# way to retrieve it.
resource "aws_iam_user_login_profile" "spc_mod" {
  user                    = aws_iam_user.spc_mod.name
  password_reset_required = false
}

# Static fallback CLI credential alongside `aws login` (see the
# SignInLocalDevelopmentAccess attachment below for the login flow itself).
resource "aws_iam_access_key" "spc_mod" {
  user = aws_iam_user.spc_mod.name
}

# Required for `aws login` to work for a plain IAM user - without this,
# the browser flow authenticates fine but the CLI gets a 400 trying to
# mint a temporary access key. Root doesn't need this; IAM users/roles do.
resource "aws_iam_group_policy_attachment" "sign_in_local_development" {
  group      = aws_iam_group.seattle_photo_club.name
  policy_arn = "arn:aws:iam::aws:policy/SignInLocalDevelopmentAccess"
}

data "aws_iam_policy_document" "site_bucket_rw" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_iam_policy" "site_bucket_rw" {
  name        = "${local.site_fqdn}-s3-rw"
  description = "Read/write access to the ${local.site_fqdn} static site bucket"
  policy      = data.aws_iam_policy_document.site_bucket_rw.json
}

resource "aws_iam_group_policy_attachment" "site_bucket_rw" {
  group      = aws_iam_group.seattle_photo_club.name
  policy_arn = aws_iam_policy.site_bucket_rw.arn
}

import {
  to = aws_iam_user.spc_mod
  id = "spc-mod"
}

import {
  to = aws_iam_group.seattle_photo_club
  id = "SeattlePhotoClub"
}

import {
  to = aws_iam_user_group_membership.spc_mod
  id = "spc-mod/SeattlePhotoClub"
}
