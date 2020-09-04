resource "aws_lambda_function" "take_screenshot" {
  filename      = "./screenshot-service.zip"
  function_name = "take_screenshot"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "screenshot-service.handler"
  runtime       = "python3.7"

  source_code_hash = filebase64sha256("./screenshot-service.zip")
  timeout          = 600
  memory_size      = 512 
  layers = ["${aws_lambda_layer_version.chromedriver_layer.arn}"]

  environment {
    variables = {
      s3_bucket = "${aws_s3_bucket.screenshot_bucket.bucket}"
    }
  }
}

resource "aws_lambda_function" "get_dns_records" {
  filename = "./dns-service.zip"
  function_name = "get_dns_records"
  role = aws_iam_role.lambda_exec_role.arn
  handler = "dns-service.handler"
  runtime = "python3.7"

  source_code_hash = filebase64sha256("./dns-service.zip")
  timeout = 150
  memory_size = 128

  environment {
    variables = {
      "RESOLVER_TIMEOUT" = var.dns_resolver_timeout,
      "RESOLVER_LIFETIME" = var.dns_resolver_lifetime,
      "DNS_RECORD_TYPES" = jsonencode(var.dns_record_types)
    }
  }
}

resource "aws_lambda_function" "get_analysis" {
  filename = "./analysis.zip"
  function_name = "get_analysis"
  role = aws_iam_role.lambda_exec_role.arn
  handler = "analysis.handler"
  runtime = "python3.7"

  source_code_hash = filebase64sha256("./analysis.zip")
  timeout = 600
  memory_size = 256

  environment {
    variables = {
      "https_default" = true,
      "apigw_key" = aws_api_gateway_api_key.apigw_prod_key.value
    }
  }
}

resource "aws_lambda_layer_version" "chromedriver_layer" {
  filename = "./chromedriver_lambda_layer.zip"
  layer_name = "chromedriver-binaries"
  source_code_hash = filebase64sha256("./chromedriver_lambda_layer.zip")
  compatible_runtimes = ["python3.7"]
}

resource "aws_iam_role" "lambda_exec_role" {
  name        = "lambda_exec_role"
  description = "Execution role for Lambda functions"

  assume_role_policy = <<EOF
{
        "Version"  : "2012-10-17",
        "Statement": [
            {
                "Action"   : "sts:AssumeRole",
                "Principal": {  
                    "Service": "lambda.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid"   : ""
            }
        ]
}
EOF

}

resource "aws_iam_role_policy" "lambda_logging" {
  name = "lambda_logging"

  role = aws_iam_role.lambda_exec_role.id

  # "Resource": "arn:aws:logs:*:*:*",
  policy = <<EOF
{
    "Version"  : "2012-10-17",
    "Statement": [
        {
            "Effect"  : "Allow",
            "Resource": "*",
            "Action"  : [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda_s3_access"

  role = aws_iam_role.lambda_exec_role.id

  # TODO: Change resource to be more restrictive
  policy = <<EOF
{
  "Version"  : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBuckets",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObjectAcl"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF

}

