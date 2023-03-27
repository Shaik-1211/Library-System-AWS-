resource "aws_lambda_function" "library_lambda" {
  function_name = "list_of_books"

  s3_bucket = aws_s3_bucket.lambda_books_bucket_salma.id
  s3_key    = aws_s3_bucket_object.lambda_books_salma.key

  runtime = "provided.al2"
  handler = "bootstrap"

  source_code_hash = "./lambda-library/lambda.zip"
  role = aws_iam_role.lambda_books_salma.arn
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.library_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.library-api-gateway.execution_arn}/*/*"
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name        = "lambda_dynamodb_access_policy_test"
  path        = "/"
  description = "IAM policy for DynamoDB access from lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
        "Statement": [
            {
                "Effect":"Allow",
                "Action": [
                    "dynamodb:*",
                    "lambda:*"
                ],
                "Resource":"*"
            }
        ]
}
EOF
}