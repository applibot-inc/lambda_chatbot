## Github Actions を Slack workflow から実行します

## 使い方

### 1. Github Tokenの準備
- 対象リポジトリの作成後、Github Tokenの発行が必要になります
- パラメータストア `/github/token/site`に登録します

### 2. AWS Chatbotの準備
- 初回のみコンソール上でslackワークスペースとの連携設定が必要になります
- 連携後、ワークススペースID `slack_workspace_id`になります

### 3. Slackチャンネル作成準備(プライベート推奨)
- 対象チャンネルを右クリックしコピーします
- https://<slack workspace名>.slack.com/archives/xxxxxxx
- xxxxxxの値を`slack_channel_id`になります

### 4. terraformでまとめて作成
- locals.tf内の環境変数を書き換え
  - `/github/token/site`
  - `slack_workspace_id`
  - `slack_channel_id`

- Goビルド、lambda、chatbotの作成をします
```shellscript
go mod tidy
terraform init
terraform plan
terraform apply
```

### 5. Github Actionsを用意
- on workflow_dispatchトリガーを指定します。(後続処理は省略しています)
- https://github.com/applibot-inc/lambda_chatbot/blob/main/.github/workflows/main.yml

### 6. Slack通知
- Slackの該当チャンネルで設定してください。
- 通知対象：mainブランチかつ、workflow_dispatchトリガーのみ通知。
```
/invite @GitHub
/github subscribe applibot-inc/lambda_chatbot workflows:{event:"repository_dispatch","workflow_dispatch" branch:"main"}
/github unsubscribe applibot-inc/lambda_chatbot  pulls commits releases deployments issues
```

### 7. Slackワークフロー設定
- 対象チャンネルにて、@awsで招待します。
- インテグレーション -> ワークフローより以下設定を行います
- ワークフローのタイトル: web siteデプロイ
- メッセージ: webサイトのデプロイを開始します
- 実行するコマンド: awsコマンド入れます
```shellscript
aws lambda invoke <lambda function> --region <region>
```
- 下記のような設定画面のようになります
<img width="1162" alt="SCR-20230502-nedr" src="https://github.com/applibot-inc/lambda_chatbot/blob/main/image/slack_workflow_result.png">

### 8. ワークフロー実行結果
- slackチャンネル内のの上段にあるワークフローより「webサイトデプロイ」をクリック
- awsコマンド実行後にスレッド内で[Run command]ボタンをクリックすることで実行されます
- Github Actionsの成功/失敗を確認できます
<img src="https://github.com/applibot-inc/lambda_chatbot/blob/main/image/slack_info.png" width="60%">
  

