resource "aws_api_gateway_rest_api" "webhook" {
  count       = var.enable_webhook_apigateway_v1 ? 1 : 0
  name        = "${var.prefix}-github-action-webhook"
  description = "GitHub App webhook for receiving build events."
  tags        = var.tags
}

resource "aws_api_gateway_resource" "webhook_resource" {
  count       = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.webhook[count.index].id
  parent_id   = aws_api_gateway_rest_api.webhook[count.index].root_resource_id
  path_part   = "$default"
}

resource "aws_api_gateway_integration" "webhook_integration" {
  count       = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.webhook[count.index].id
  resource_id = aws_api_gateway_resource.webhook_resource[count.index].id
  http_method = aws_api_gateway_method.webhook_method[count.index].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook.invoke_arn

  cache_key_parameters = ["method.request.path.proxy"]

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method" "webhook_method" {
  count         = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.webhook[count.index].id
  resource_id   = aws_api_gateway_resource.webhook_resource[count.index].id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}
resource "aws_api_gateway_method" "root" {
  count         = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.webhook[count.index].id
  resource_id   = aws_api_gateway_rest_api.webhook[count.index].root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# Integrate API Gateway root route with Lambda function
resource "aws_api_gateway_integration" "root" {
  count                   = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.webhook[count.index].id
  resource_id             = aws_api_gateway_rest_api.webhook[count.index].root_resource_id
  http_method             = aws_api_gateway_method.root[count.index].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.webhook.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook_deployment" {
  count      = var.enable_webhook_apigateway_v1 ? 1 : 0
  depends_on = [aws_api_gateway_integration.webhook_integration]

  rest_api_id = aws_api_gateway_rest_api.webhook[count.index].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.webhook_resource,
      aws_api_gateway_method.webhook_method,
      aws_api_gateway_integration.webhook_integration,
      aws_api_gateway_method.root,
      aws_api_gateway_integration.root
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "webhook_stage" {
  count         = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.webhook[count.index].id
  stage_name    = "devt"
  deployment_id = aws_api_gateway_deployment.webhook_deployment[count.index].id

  dynamic "access_log_settings" {
    for_each = var.webhook_lambda_apigateway_access_log_settings[*]
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }
  tags = var.tags
}

resource "aws_api_gateway_method_settings" "api_method_settings" {
  count       = var.enable_webhook_apigateway_v1 ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.webhook[count.index].id
  stage_name  = aws_api_gateway_stage.webhook_stage[count.index].stage_name
  method_path = "*/*"

  settings {
    logging_level   = "OFF"
    caching_enabled = true
  }
}
