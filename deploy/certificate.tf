data "aws_route53_zone" "library_zone" {
  name = "atom.cloud"
  private_zone = false
}

resource "aws_acm_certificate" "library_certificate" {
  domain_name       = "api-librarysystem.atom.cloud"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "library_validation" {
  for_each = {
    for dvo in aws_acm_certificate.library_certificate.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }
    zone_id = data.aws_route53_zone.library_zone.zone_id
    allow_overwrite = true
    name = each.value.name
    records = [each.value.record]
    ttl = 60
    type ="CNAME"

}

 resource "aws_acm_certificate_validation" "library_acm"{
     certificate_arn =  aws_acm_certificate.library_certificate.arn
     validation_record_fqdns = [for record in aws_route53_record.library_validation : record.fqdn]
  }
