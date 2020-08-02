output "api_gateway_url" {
  value = "${aws_api_gateway_stage.prod_stage.invoke_url}/${aws_api_gateway_resource.screenshot_api_gateway.path_part}"
}

output "api_key" {
  value = aws_api_gateway_api_key.apigw_prod_key.value
}