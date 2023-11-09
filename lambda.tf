# Lambda Function
resource "aws_lambda_function" "lambda" {
  description      = "Site Deploy"
  filename         = "${path.module}/lambda/archive/main.zip"
  function_name    = local.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "main"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 15
  publish          = true
  environment {
    variables = {
      BRANCH          = local.variables_BRANCH
      REPO_NAME       = local.variables_REPO_NAME
      REPO_OWNER      = local.variables_REPO_OWNER
      WORKFLOW_NAME   = local.variables_WORKFLOW_NAME
      PARAMETER_STORE = local.variables_PARAMETER_STORE
    }
  }
}

resource "null_resource" "lambda" {
  triggers = {
    file_content = md5(file("${path.module}/lambda/source/main.go"))
  }

  provisioner "local-exec" {
    command = "GOOS=linux GOARCH=amd64 go build -o ${path.module}/lambda/bin/main ${path.module}/lambda/source/main.go"
  }
}

data "archive_file" "lambda" {
  depends_on       = [null_resource.lambda]
  type             = "zip"
  source_dir       = "${path.module}/lambda/bin/"
  output_path      = "${path.module}/lambda/archive/main.zip"
  output_file_mode = "0666"
}

# IAM Role
resource "aws_iam_role" "lambda" {
  name = local.lambda_role_name
  path = "/service-role/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ssm" {
  name = "ssm"
  role = aws_iam_role.lambda.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
