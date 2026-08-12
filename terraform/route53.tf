resource "aws_route53_zone" "site" {
  name = var.domain_name
}

resource "aws_route53_record" "site_ipv4" {
  zone_id = aws_route53_zone.site.zone_id
  name    = local.primary_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_ipv6" {
  zone_id = aws_route53_zone.site.zone_id
  name    = local.primary_fqdn
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# The old site_ipv4/ipv6 records above are being renamed away from
# local.redirect_fqdn ("www...") in this same apply; depends_on forces that
# rename to finish before these are created, avoiding a duplicate-record
# conflict on the "www" name in Route 53.
resource "aws_route53_record" "www_redirect_ipv4" {
  depends_on = [aws_route53_record.site_ipv4, aws_route53_record.site_ipv6]

  zone_id = aws_route53_zone.site.zone_id
  name    = local.redirect_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.www_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_redirect_ipv6" {
  depends_on = [aws_route53_record.site_ipv4, aws_route53_record.site_ipv6]

  zone_id = aws_route53_zone.site.zone_id
  name    = local.redirect_fqdn
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.www_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.www_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
