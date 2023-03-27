resource "aws_s3_bucket_object" "html"{
  for_each =fileset("../cdn/dist","**/*.html")
  bucket=aws_s3_bucket.lambda_books_bucket_salma.id
  key=each.value
  source = "../cdn/dist/${each.value}"
  etag=filemd5("../cdn/dist/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "css" {
  for_each = fileset("../cdn/dist", "**/*.css")

  bucket       = aws_s3_bucket.lambda_books_bucket_salma.id
  key          = each.value
  source       = "../cdn/dist/${each.value}"
  etag         = filemd5("../cdn/dist/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "js" {
  for_each = fileset("../cdn/dist", "**/*.js")

  bucket       = aws_s3_bucket.lambda_books_bucket_salma.id
  key          = each.value
  source       = "../cdn/dist/${each.value}"
  etag         = filemd5("../cdn/dist/${each.value}")
  content_type = "application/javascript"
}

resource "aws_s3_bucket_object" "ico" {
  for_each     = fileset("../cdn/dist", "**/*.ico")
  bucket       = aws_s3_bucket.lambda_books_bucket_salma.id
  key          = each.value
  source       = "../cdn/dist/${each.value}"
  etag         = filemd5("../cdn/dist/${each.value}")
  content_type = "image/x-icon"
}
locals{
    s3_origin_id=aws_s3_bucket.lambda_books_bucket_salma.id
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "dev.atom-spikes"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.lambda_books_bucket_salma.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  aliases = ["librarysystem.atom.cloud"]
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "library-cloudfront"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "development"
    Name        = "atom-spikes-cdn"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = "arn:aws:acm:us-east-1:737151555887:certificate/42b977b4-095d-4e77-ae89-3d593fefcaac"
    /* acm_certificate_arn = aws_acm_certificate.library_certificate.arn */
    ssl_support_method = "sni-only"
  }
  depends_on = [
    aws_s3_bucket.lambda_books_bucket_salma,
    /* aws_api_gateway_rest_api.library-api-gateway, */
  ]
}

# to get the Cloud front URL if doamin/alias is not configured
output "cloudfront_domain_name" {
    description = "Cloudfront domain name"
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.lambda_books_bucket_salma.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "lambda_books_bucket_policy" {
  bucket = aws_s3_bucket.lambda_books_bucket_salma.bucket
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket_public_access_block" "lambda_books_bucket" {
  bucket = aws_s3_bucket.lambda_books_bucket_salma.id

  block_public_acls   = true
  block_public_policy = true
}


resource "aws_route53_record" "library-system" {
  zone_id = data.aws_route53_zone.route53-data.zone_id
  name    = "librarysystem.atom.cloud"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
