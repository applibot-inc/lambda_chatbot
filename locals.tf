# lambda
locals {
  function_name             = "site-deploy"             # Lambda関数名
  lambda_role_name          = "site-deploy-lambda-role" # Lambdaロール名
  variables_BRANCH          = "main"                    # 対象branch
  variables_REPO_NAME       = "lambda_chatbot"          # Githubリポジトリ名
  variables_REPO_OWNER      = "applibot-inc"            # Githubリポジトリオーナ名
  variables_WORKFLOW_NAME   = "main.yml"                # 実行したいworkflowファイル名
  variables_PARAMETER_STORE = "/github/token/site"      # Github Token(パラメータストアのパス)
}

# chatbot
locals {
  configuration_name = "site-deploy"              # Chatbotリソース名
  chatbot_role_name  = "site-deploy-chatbot-role" # Chatbotロール名
  slack_workspace_id = "**********"               # slackのワークスペースID
  slack_channel_id   = "***********"              # 対象チャンネルID (ex. site-deploy)
}
