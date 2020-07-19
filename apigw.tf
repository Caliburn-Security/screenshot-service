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

resource "aws_api_gateway_account" "apigw_account" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

#resource "aws_api_gateway_method_settings" "apigw_settings" {
#  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
#  method_path = "*/*"


#  settings {
#    metrics_enabled = true
#    logging_level = "DEBUG"
#    data_trace_enabled = true

#    throttling_rate_limit = 100
#    throttling_burst_limit = 50
#  }
#}

/* resource "aws_api_gateway_method" "take_screenshot_post" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.screenshot_api_gateway.id
  http_method   = "POST"
  authorization = "NONE"
} */

resource "aws_api_gateway_method" "take_screenshot_get" {
  rest_api_id   = aws_api_gateway_rest_api.screenshot_api.id
  resource_id   = aws_api_gateway_resource.screenshot_api_gateway.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_stage" "prod_stage" {
  stage_name = "prod"
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment_get.id
}

/* resource "aws_api_gateway_integration" "lambda_integration_post" {
  depends_on = [
    aws_lambda_permission.apigw
  ]
  
  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
  resource_id = aws_api_gateway_method.take_screenshot_post.resource_id
  http_method = aws_api_gateway_method.take_screenshot_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.take_screenshot.invoke_arn
} */

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

/* resource "aws_api_gateway_deployment" "api_gateway_deployment_post" {
  depends_on = [aws_api_gateway_integration.lambda_integration_post,  aws_api_gateway_method.take_screenshot_post]

  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
} */

resource "aws_api_gateway_deployment" "api_gateway_deployment_get" {
  depends_on = [aws_api_gateway_integration.lambda_integration_get,  aws_api_gateway_method.take_screenshot_get]

  rest_api_id = aws_api_gateway_rest_api.screenshot_api.id
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.take_screenshot.arn
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