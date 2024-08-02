output "gateway" {
  value = one(aws_apigatewayv2_api.webhook[*])
}

output "gatewayv1" {
  value = one(aws_api_gateway_rest_api.webhook[*])
}

output "lambda" {
  value = aws_lambda_function.webhook
}

output "lambda_log_group" {
  value = aws_cloudwatch_log_group.webhook
}

output "role" {
  value = aws_iam_role.webhook_lambda
}

output "gateway_endpoint" {
  description = "Gateway endpoint"
  value       = one(aws_apigatewayv2_api.webhook[*].api_endpoint)
}

output "endpoint_relative_path" {
  value = local.webhook_endpoint
}

output "rest_api_id" {
  description = "REST API id"
  value       = one(aws_api_gateway_rest_api.webhook[*].id)
}

output "deployment_id" {
  description = "Deployment id"
  value       = one(aws_api_gateway_deployment.webhook_deployment[*].id)
}

output "deployment_invoke_url" {
  description = "Deployment invoke url"
  value       = one(aws_api_gateway_deployment.webhook_deployment[*].invoke_url)
}
