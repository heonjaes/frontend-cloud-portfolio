terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "ap-southeast-2"
  access_key = "AKIA6P6OLOYQAQMI7RHU"
  secret_key = "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"
}

# S3 Bucket
resource "aws_s3_bucket" "website" {
  bucket = "heonjae-resume-website"
}

resource "aws_s3_bucket_policy" "read_only" {
  bucket = aws_s3_bucket.website.bucket
  policy = <<EOF

  {
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::heonjae-resume-website/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "arn:aws:cloudfront::996328306208:distribution/EV9QGY7HPIUHS"
            }
        }
    }
}
EOF
}


resource "aws_cloudfront_origin_access_control" "resume" {
  name                              = "CloudFront S3 OAC"
  description                       = "Cloud Front S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.resume.id

  }

  aliases = ["resume.heonjaeshin.com"]

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:996328306208:certificate/fe394b1b-3707-4ebf-8c66-fecfed1d0583"
    ssl_support_method = "sni-only"
  }

}

resource "aws_dynamodb_table" "table" {
  name           = "resume-count-table"
    billing_mode = "PAY_PER_REQUEST"
  hash_key = "ID"


  attribute {
    name = "ID"
    type = "S"
  }

}

resource "aws_dynamodb_table_item" "test" {
  table_name = aws_dynamodb_table.table.name
  hash_key   = aws_dynamodb_table.table.hash_key

  lifecycle {
    ignore_changes = all
  }

  item = <<ITEM
{
  "ID": {"S": "0"},
  "visit_count":{"N":"0"}
}
ITEM
}

# Route53
resource "aws_route53_zone" "resume_website" {
  name = "heonjaeshin.com"
}

resource "aws_route53_record" "resume_website" {
  zone_id = aws_route53_zone.resume_website.zone_id
  name    = "resume.heonjaeshin.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = "Z04440273K3ZAVYW6TKKI"
    evaluate_target_health = false
  }
}

# Lambda
resource "aws_lambda_function" "lambda_py" {
  filename      = "lambda/lambda4dynamodb.zip"
  function_name = "py_lambda"
  role          = aws_iam_role.assume_policy.arn
  runtime = "python3.9"
  handler       = "lambda4dynamodb.lambda_handler"
  source_code_hash = filebase64sha256("lambda/lambda4dynamodb.zip")

}

resource "aws_iam_role" "assume_policy" {
  name = "visit_count_access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_resume_project" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
    policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
			      "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/resume-count-table"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "iam_policy_to_iam_role" {
  role = aws_iam_role.assume_policy.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn
  
}

resource "aws_lambda_function_url" "counter_url" {
  function_name      = aws_lambda_function.lambda_py.function_name
  authorization_type = "NONE"

   cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}




# API Gateway
resource "aws_iam_policy" "api_gateway_access" {
  name   = "api_gateway_access_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "cloudfront:GetDistribution",
      "Resource": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.website_distribution.id}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.website.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.website.id}"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
resource "aws_iam_role_policy_attachment" "api_gateway_access" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_access.arn
}
resource "aws_api_gateway_rest_api" "resume-website" {
  name = "API for my Heonjae's website"
}
resource "aws_api_gateway_method" "resume-website" {
  rest_api_id   = aws_api_gateway_rest_api.resume-website.id
  resource_id   = aws_api_gateway_rest_api.resume-website.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "resume-website" {
  rest_api_id = aws_api_gateway_rest_api.resume-website.id
  resource_id = aws_api_gateway_rest_api.resume-website.root_resource_id
  http_method = aws_api_gateway_method.resume-website.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_py.invoke_arn
}
data "aws_caller_identity" "current" {}
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_py.arn
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:ap-southeast-2:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.resume-website.id}/*/*"
}
resource "aws_api_gateway_method_response" "resume-website" {
  depends_on      = [aws_api_gateway_method.resume-website]
  rest_api_id     = aws_api_gateway_rest_api.resume-website.id
  resource_id     = aws_api_gateway_rest_api.resume-website.root_resource_id
  http_method     = aws_api_gateway_method.resume-website.http_method
  status_code     = 200
  response_models = { "application/json" = "Empty" }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true,
  }
}

  resource "aws_api_gateway_integration_response" "resume-website" {
    rest_api_id = aws_api_gateway_rest_api.resume-website.id
    resource_id = aws_api_gateway_rest_api.resume-website.root_resource_id
    http_method = aws_api_gateway_method.resume-website.http_method
    status_code = "200"
    response_parameters = {
      "method.response.header.Access-Control-Allow-Headers" = "'*'",
      "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS,GET,PUT,PATCH,DELETE'",
      "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    }
  }

resource "aws_api_gateway_deployment" "resume-website" {
  depends_on  = [aws_api_gateway_integration_response.resume-website, aws_api_gateway_integration.resume-website]
  rest_api_id = aws_api_gateway_rest_api.resume-website.id
  stage_name  = "dev1"
}