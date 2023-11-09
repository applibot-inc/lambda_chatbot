# Chatbot
resource "awscc_chatbot_slack_channel_configuration" "chatbot" {
  configuration_name = local.configuration_name
  slack_workspace_id = local.slack_workspace_id
  slack_channel_id   = local.slack_channel_id
  iam_role_arn       = aws_iam_role.chatbot.arn # チャンネルロール(IAM Role)
  guardrail_policies = [
    aws_iam_policy.chatbot_guardrail.arn # ガードレールポリシ (チャンネルロールよりも優先)
  ]

  logging_level = "ERROR"

  depends_on = [
    aws_iam_role.chatbot,
    aws_iam_policy.chatbot_guardrail
  ]
}

resource "aws_iam_role" "chatbot" {
  name               = local.chatbot_role_name
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume.json
}

data "aws_iam_policy_document" "chatbot_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "chatbot.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "chatbot_guardrail" {
  name   = "${local.configuration_name}_chatbot_guardrail_policy"
  policy = data.aws_iam_policy_document.chatbot_guardrail.json
}

data "aws_iam_policy_document" "chatbot_guardrail" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:invokeAsync",
      "lambda:invokeFunction"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]

    resources = [
      "*",
    ]
  }
}

# 以下、IAMロール ポリシー (ガードレールポリシと同じもの)
resource "aws_iam_role_policy_attachment" "chatbot_readonly" {
  role       = aws_iam_role.chatbot.id
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"
}

resource "aws_iam_role_policy" "chatbot_lambda" {
  name = "lambda"
  role = aws_iam_role.chatbot.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:invokeAsync",
                "lambda:invokeFunction"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "chatbot_noti" {
  name = "AWS-Chatbot-NotificationsOnly-Policy"
  role = aws_iam_role.chatbot.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}
