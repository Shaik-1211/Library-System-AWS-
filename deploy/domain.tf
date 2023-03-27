#create a domain_name 
resource "aws_api_gateway_domain_name" "library_system_domain" {
  domain_name = "api-librarysystem.atom.cloud"
  regional_certificate_arn = aws_acm_certificate.library_certificate.arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}



resource "aws_route53_record" "library_record" {
  name = aws_api_gateway_domain_name.library_system_domain.domain_name
  type = "A"
  zone_id = data.aws_route53_zone.library_zone.zone_id

  alias {
    name = aws_api_gateway_domain_name.library_system_domain.regional_domain_name
    zone_id = aws_api_gateway_domain_name.library_system_domain.regional_zone_id
    evaluate_target_health = true
  }
}

resource "aws_api_gateway_base_path_mapping" "library_api_map" {
  api_id      = aws_api_gateway_rest_api.library-api-gateway.id
  domain_name = aws_api_gateway_domain_name.library_system_domain.domain_name
  stage_name  =  aws_api_gateway_stage.library_api_stage.stage_name
}
