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

4. Upload your site content to the bucket (Terraform doesn't manage page
   content, so future deploys don't require `terraform apply`):

   ```
   aws s3 sync ./dist s3://$(terraform output -raw s3_bucket_name)
   ```

5. After uploading new content, invalidate the CloudFront cache:

   ```
   aws cloudfront create-invalidation \
     --distribution-id $(terraform output -raw cloudfront_distribution_id) \
     --paths "/*"
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
