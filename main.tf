data "archive_file" "screenshot_service_zip" {
  type        = "zip"
  source_dir  = "./lambda/screenshot-service"
  output_path = "./screenshot-service.zip"
}

data "archive_file" "screenshot_service_layers_zip" {
  type = "zip"
  source_dir = "./chromedriver_lambda_layer"
  output_path = "./chromedriver_lambda_layer.zip"
}

data "archive_file" "dns_service_zip" {
  type = "zip"
  source_dir = "./lambda/dns-service"
  output_path = "./dns-service.zip"
}

data "archive_file" "analysis_zip" {
  type = "zip"
  source_dir = "./lambda/analysis"
  output_path = "./analysis.zip"
}