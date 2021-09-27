resource "aws_cognito_user_pool" "user_pool" {
  name = "CognitoUserPool"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                          = "CognitoUserPoolClient"
  prevent_user_existence_errors = "ENABLED"

  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_api_gateway_rest_api" "rest_api_gateway" {
  name = "restApiGateway"
}

resource "aws_api_gateway_authorizer" "api_gateway_authorizer" {
  name            = "CognitoAuthorizer"
  identity_source = "method.request.header.Authorization"
  provider_arns = [
    aws_cognito_user_pool.user_pool.arn
  ]
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
  type        = "COGNITO_USER_POOLS"
}

resource "aws_api_gateway_resource" "hello_api_gateway_resource" {
  parent_id   = aws_api_gateway_rest_api.rest_api_gateway.root_resource_id
  path_part   = "hello"
  rest_api_id = aws_api_gateway_rest_api.rest_api_gateway.id
}

resource "aws_api_gateway_method" "get_hello" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.hello_api_gateway_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api_gateway.id
}

resource "aws_iam_role" "hello_lambda_role" {
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Effect\":\"Allow\",\"Sid\":\"\"}]}"
  description        = "Basic Lambda Execution Role"
}

resource "aws_dynamodb_table" "hello_db_table" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "keyid"
  name         = "ddbHelloTable"
  attribute = [
    {
      name = "keyid"
      type = "S"
    }
  ]
}

resource "aws_iam_role_policy" "hello_lambda_role_policy" {
  name   = "PermissionsForLambda"
  policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"logs:CreateLogGroup\",\"logs:CreateLogStream\",\"logs:PutLogEvents\"],\"Resource\":\"*\"},{\"Sid\":\"VisualEditor0\",\"Effect\":\"Allow\",\"Action\":\"dynamodb:Query\",\"Resource\":\"${aws_dynamodb_table.Hello_ddbHelloTable_8843095A.arn}\"}]}"
  role   = aws_iam_role.hello_lambda_role.name
  depends_on = [
    aws_iam_role.hello_lambda_role
  ]
}

resource "aws_lambda_function" "hello_lambda_function" {
  description      = "This is our first lambda in myapp1"
  filename         = "assets/Hello_hello-source-code_CE9C9C11/B769FE9E0A90DEB299E9C5A8CA8029D8/archive.zip"
  function_name    = "helloWorlddb"
  handler          = "index.Handler"
  role             = aws_iam_role.hello_lambda_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = "B769FE9E0A90DEB299E9C5A8CA8029D8"
  timeout          = 61
  environment = [
    {
      variables = {
        "DDB_TABLE" = "${aws_dynamodb_table.hello_db_table.name}"
      }
    }
  ]

}

resource "aws_api_gateway_integration" "hello_api_gateway_integration" {
  http_method             = aws_api_gateway_method.get_hello.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.hello_api_gateway_resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest_api_gateway.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda_function.invoke_arn
  depends_on = [
    aws_api_gateway_method.API_api-gateway-get-hello_EFD72315
  ]
}

resource "aws_lambda_permission" "hello_lambda_function_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.Hello_region.name}:${data.aws_caller_identity.Hello_userId.account_id}:${aws_api_gateway_rest_api.rest_api_gateway.id}/*/${aws_api_gateway_method.get_hello.http_method}${aws_api_gateway_resource.hello_api_gateway_resource.path}"
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  description       = "Production environment deployment"
  rest_api_id       = aws_api_gateway_rest_api.rest_api_gateway.id
  stage_description = "Production Environment"
  stage_name        = "prod"
  depends_on = [
    aws_api_gateway_method.get_hello,
    aws_api_gateway_integration.hello_api_gateway_integration
  ]
}

