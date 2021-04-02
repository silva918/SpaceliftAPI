## MAIN file

terraform {
  required_providers {
    spacelift = {
      source = "spacelift.io/spacelift-io/spacelift"
    }
  }
}

provider "aws" {
   region = "us-east-1"
   profile = "demo"
}

variable "spacelift_key_id" {
  type = string
  default = "01F29TRC98N94HA00W76AH0DK3"
}

variable "spacelift_key_secret" {
  type = string
  default = "2eca0cc176621073b119f7d83bd91fe5ab4dcba2f5bcd7b65065b3909e190f37"
}

variable "spacelift_key_endpoint" {
  type = string
  default = "https://silva918.app.spacelift.io/stack/silvastack"
}

provider "spacelift" {
  api_key_endpoint = var.spacelift_key_endpoint
  api_key_id       = var.spacelift_key_id
  api_key_secret   = var.spacelift_key_secret

}

data "aws_caller_identity" "current" {}

output "account_id_output" {
  value = data.aws_caller_identity.current.account_id
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}


resource "aws_dynamodb_table" "ddbtable" {
  name             = "myDB"
  hash_key         = "eventID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "eventID"
    type = "S"
  }
}

resource "aws_iam_role_policy" "apiGateway_policy" {
  name = "apiGateway_policy"
  role = aws_iam_role.role_for_APIG.id

  policy = templatefile("policy.json", {account = local.account_id})
}


resource "aws_iam_role" "role_for_APIG" {
  name = "myrole"

  assume_role_policy = file("assume_role_policy.json")

}

resource "aws_api_gateway_rest_api" "SpaceliftEventsAPI" {
  name  = "SpaceliftEventsAPI"
}


  resource "aws_api_gateway_resource" "Resource" {
  rest_api_id = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
  parent_id   = aws_api_gateway_rest_api.SpaceliftEventsAPI.root_resource_id
  path_part   = "dynamoTable"

}


resource "aws_api_gateway_method" "Method" {
   rest_api_id   = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
   resource_id   = aws_api_gateway_resource.Resource.id
   http_method   = "POST"
   authorization = "NONE"
}


resource "aws_api_gateway_integration" "dynamoPutItem" {
   rest_api_id = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
   resource_id = aws_api_gateway_resource.Resource.id
   http_method = aws_api_gateway_method.Method.http_method

   type = "AWS"
   integration_http_method = "POST"
   uri = "arn:aws:apigateway:us-east-1:dynamodb:action/PutItem"
   credentials = aws_iam_role.role_for_APIG.arn
   # (...)
   request_templates = {
    "application/json" = file("./mappingTemplate.json")
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
  resource_id = aws_api_gateway_resource.Resource.id
  http_method = aws_api_gateway_method.Method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
  resource_id = aws_api_gateway_resource.Resource.id
  http_method = aws_api_gateway_method.Method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

}

resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [aws_api_gateway_integration.dynamoPutItem]

   rest_api_id = aws_api_gateway_rest_api.SpaceliftEventsAPI.id
   stage_name  = "Prod"
}


output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}
