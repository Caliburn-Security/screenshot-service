resource "aws_api_gateway_rest_api" "screenshot_api" {
  name        = "screenshot_api"
  description = "Lambda-powered screenshot API"
  depends_on = [
    aws_lambda_function.take_screenshot
  ]
}

resource "aws_api_gateway_resource" "screenshot_api_gateway" {
  path_part   = "screenshot"
  parent_id   = aws_api_gateway_rest_api.screenshot_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
}

resource "aws_api_gateway_resource" "dns_api_gateway" {
  path_part = "dns"
  parent_id   = aws_api_gateway_rest_api.screenshot_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
}

resource "aws_api_gateway_resource" "analysis_api_gateway" {
  path_part = "analysis"
  parent_id   = aws_api_gateway_rest_api.screenshot_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
}

resource "aws_api_gateway_account" "apigw_account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

resource "aws_api_gateway_method" "take_screenshot_get" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.screenshot_api_gateway.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "dns_records_get" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.dns_api_gateway.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "analysis_records_get" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.analysis_api_gateway.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

/* resource "aws_api_gateway_method" "take_screenshot_post" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.screenshot_api_gateway.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
} */


resource "aws_api_gateway_stage" "prod_stage" {
  stage_name = "prod"
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment_get.id
}

resource "aws_api_gateway_usage_plan" "apigw_usage_plan" {
  name = "apigw_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.screenshot_api.id
    stage = aws_api_gateway_stage.prod_stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "apigw_usage_plan_key" {
  key_id = aws_api_gateway_api_key.apigw_prod_key.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.apigw_usage_plan.id
}

resource "aws_api_gateway_api_key" "apigw_prod_key" {
  name = "prod_key"
}

resource "aws_api_gateway_integration" "lambda_integration_get" {
  depends_on = [
    aws_lambda_permission.apigw
  ]
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  resource_id = aws_api_gateway_method.take_screenshot_get.resource_id
  http_method = aws_api_gateway_method.take_screenshot_get.http_method

  integration_http_method = "POST" # https://github.com/hashicorp/terraform/issues/9271 Lambda requires POST as the integration type
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.take_screenshot.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_integrationdns_dns_get" {
  depends_on = [
    aws_lambda_permission.apigw_dns
  ]
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  resource_id = aws_api_gateway_method.dns_records_get.resource_id
  http_method = aws_api_gateway_method.dns_records_get.http_method

  integration_http_method = "POST" # https://github.com/hashicorp/terraform/issues/9271 Lambda requires POST as the integration type
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_dns_records.invoke_arn
}

resource "aws_api_gateway_integration" "lambda_integrationdns_analysis_get" {
  depends_on = [
    aws_lambda_permission.apigw_analysis
  ]
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  resource_id = aws_api_gateway_method.analysis_records_get.resource_id
  http_method = aws_api_gateway_method.analysis_records_get.http_method

  integration_http_method = "POST" # https://github.com/hashicorp/terraform/issues/9271 Lambda requires POST as the integration type
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_analysis.invoke_arn
}

/* resource "aws_api_gateway_integration" "lambda_integration_post" {
  depends_on = [
    aws_lambda_permission.apigw
  ]
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  resource_id = aws_api_gateway_method.take_screenshot_post.resource_id
  http_method = aws_api_gateway_method.take_screenshot_post.http_method

  integration_http_method = "POST" # https://github.com/hashicorp/terraform/issues/9271 Lambda requires POST as the integration type
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.take_screenshot.invoke_arn
} */

resource "aws_api_gateway_deployment" "api_gateway_deployment_get" {
  depends_on = [aws_api_gateway_integration.lambda_integration_get,  aws_api_gateway_method.take_screenshot_get, aws_api_gateway_method.dns_records_get, aws_api_gateway_method.analysis_records_get /*aws_api_gateway_integration.lambda_integration_post, aws_api_gateway_method.take_screenshot_post*/]

  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.take_screenshot.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.screenshot_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_dns" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_dns_records.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.screenshot_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "apigw_analysis" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_analysis.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.screenshot_api.execution_arn}/*/*/*"
}

resource "aws_iam_role" "apigw_cloudwatch" {
  # https://gist.github.com/edonosotti/6e826a70c2712d024b730f61d8b8edfc
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "apigw_cloudwatch" {
  name = "default"
  role = aws_iam_role.apigw_cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}