resource "aws_api_gateway_rest_api" "library-api-gateway" {
  name           = "Library_API_Spike"
  description    = "Library System API"
  api_key_source = "HEADER"
  body           = data.template_file.library.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

data "template_file" "library" {
  template = file("api.json")

  vars = {
    get_lambda_arn          = "${aws_lambda_function.library_lambda.arn}"
    aws_region              = "ap-south-1"
    lambda_identity_timeout = 1000
  }

}

resource "aws_api_gateway_stage" "library_api_stage" {
  deployment_id = aws_api_gateway_deployment.library_api_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.library-api-gateway.id
  stage_name    = "LibrayStage"
}

resource "aws_api_gateway_deployment" "library_api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.library-api-gateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.library-api-gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# output "url" {
#   value = "${aws_api_gateway_deployment.library_api_deploy.invoke_url}/"
# }

resource "aws_api_gateway_api_key" "library_api_key" {
  name = "LibraryAPIKey"
}

resource "aws_api_gateway_usage_plan_key" "devUsageKey" {
  key_id        = aws_api_gateway_api_key.library_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.DevUsagePlan.id
}

resource "aws_api_gateway_usage_plan" "DevUsagePlan" {
  name         = "dev-usage-plan"
  description  = "dev usage plan for library api"
  product_code = "libraryAPI"

  api_stages {
    api_id = aws_api_gateway_rest_api.library-api-gateway.id
    stage  = aws_api_gateway_stage.library_api_stage.stage_name
  }

  quota_settings {
    limit  = 1000
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 100
  }
}