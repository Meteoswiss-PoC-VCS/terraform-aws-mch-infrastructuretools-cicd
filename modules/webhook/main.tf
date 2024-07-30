locals {
  webhook_endpoint = "webhook"
  role_path        = var.role_path == null ? "/${var.prefix}/" : var.role_path
  lambda_zip       = var.lambda_zip == null ? "${path.module}/../../lambdas/functions/webhook/webhook.zip" : var.lambda_zip
}

#resource "aws_apigatewayv2_api" "webhook" {
#  name          = "${var.prefix}-github-action-webhook"
#  protocol_type = "HTTP"
#  tags          = var.tags
#}

resource "aws_api_gateway_rest_api" "webhook" {
  name = "${var.prefix}-github-action-webhook"
  tags          = var.tags
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.webhook.id
  parent_id   = aws_api_gateway_rest_api.webhook.root_resource_id
  path_part   = "{proxy+}"
}
/*
resource "aws_apigatewayv2_route" "webhook" {
  api_id    = aws_apigatewayv2_api.webhook.id
  route_key = "POST /${local.webhook_endpoint}"
  target    = "integrations/${aws_apigatewayv2_integration.webhook.id}"
}

resource "aws_apigatewayv2_integration" "webhook" {
  lifecycle {
    ignore_changes = [
      # not terraform managed
      passthrough_behavior
    ]
  }

  api_id           = aws_apigatewayv2_api.webhook.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "GitHub App webhook for receiving build events."
  integration_method = "POST"
  integration_uri    = aws_lambda_function.webhook.invoke_arn
}*/

resource "aws_api_gateway_integration" "webhook" {
  rest_api_id             = aws_api_gateway_rest_api.webhook.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  integration_http_method = "POST" 
  type                    = "AWS_PROXY"
  http_method             = aws_api_gateway_method.proxy.http_method
  uri                     = aws_lambda_function.webhook.invoke_arn

  cache_key_parameters = ["method.request.path.proxy"]

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.webhook.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.webhook]

  rest_api_id = aws_api_gateway_rest_api.function_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id        = aws_api_gateway_deployment.api_deployment.id
  rest_api_id          = aws_api_gateway_rest_api.weebhook.id
  stage_name           = "default"
}

resource "aws_api_gateway_method_settings" "api_method_settings" {
  rest_api_id = aws_api_gateway_rest_api.weebhook.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    logging_level   = "INFO"
    caching_enabled = true
  }
}



/*resource "aws_apigatewayv2_stage" "webhook" {
  lifecycle {
    ignore_changes = [
      # see bug https://github.com/terraform-providers/terraform-provider-aws/issues/12893
      default_route_settings,
      # not terraform managed
      deployment_id
    ]
  }

  api_id      = aws_apigatewayv2_api.webhook.id
  name        = "$default"
  auto_deploy = true
  dynamic "access_log_settings" {
    for_each = var.webhook_lambda_apigateway_access_log_settings[*]
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }
  tags = var.tags
}
*/

resource "aws_ssm_parameter" "runner_matcher_config" {
  name  = "${var.ssm_paths.root}/${var.ssm_paths.webhook}/runner-matcher-config"
  type  = "String"
  value = jsonencode(local.runner_matcher_config_sorted)
  tier  = var.matcher_config_parameter_store_tier
}
