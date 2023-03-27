# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_books_bucket_salma.id
}
# output API base-url
output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_api_gateway_stage.library_api_stage.invoke_url
}
# outputs
output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.library_lambda.function_name
}
