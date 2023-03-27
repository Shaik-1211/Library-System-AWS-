terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "random_pet" "lambda_bucket" {
  prefix = "lambda-function"
  length = 2
}

resource "aws_s3_bucket" "lambda_books_bucket_salma" {
  bucket = random_pet.lambda_bucket.id

  acl           = "public-read"
  force_destroy = true
  website {
    index_document="index.html"
  }
  tags = {
    Environment = "development"
    Name        = "Demo app"
  }
}

resource "aws_s3_bucket_object" "lambda_books_salma" {
  bucket = aws_s3_bucket.lambda_books_bucket_salma.id

  key    = "lambda.zip"
  source = "../lambda-library/lambda.zip"
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.library_lambda.function_name}"

  retention_in_days = 30
} 

resource "aws_iam_role" "lambda_books_salma" {
  name = "lambda_books"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole"]
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_books_salma.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}
# creating HTTP API with APIGateway

resource "aws_cloudwatch_log_group" "lambda_api_gw_salma" {
  name = "/aws/api_gw_salma/${aws_api_gateway_rest_api.library-api-gateway.name}"

  retention_in_days = 30
}

data "aws_route53_zone" "route53-data" {
  name = "atom.cloud"
}
  