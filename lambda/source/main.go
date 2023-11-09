package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ssm"
	"io"
	"log"
	"net/http"
	"os"
)

type WorkflowDispatchPayload struct {
	Ref string `json:"ref,omitempty"`
	//Inputs map[string]interface{} `json:"inputs,omitempty"`
}

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context) {
	// AWS Systems Manager パラメータストアからGitHubトークンを取得
	// githubToken := os.Getenv("GITHUB_TOKEN")
	paramerStore := os.Getenv("PARAMETER_STORE")
	githubToken, err := getGitHubTokenFromParameterStore(paramerStore)
	if err != nil {
		fmt.Printf("Failed to get GitHub token: %v", err)
		return
	}

	// GitHubリポジトリとワークフローの情報
	repoOwner := os.Getenv("REPO_OWNER")
	repoName := os.Getenv("REPO_NAME")
	workflowName := os.Getenv("WORKFLOW_NAME")

	// Workflow DispatchのPayloadを構築
	payload := WorkflowDispatchPayload{
		Ref: os.Getenv("BRANCH"), // 実行するブランチ名
		//Inputs: map[string]interface{}{
		//    "name": "fromLambda", // ワークフローに渡すパラメータ（オプション）
		//},
	}

	// Workflow Dispatchのリクエストを作成
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		fmt.Printf("Failed to marshal payload: %v", err)
		return
	}

	url := fmt.Sprintf("https://api.github.com/repos/%s/%s/actions/workflows/%s/dispatches", repoOwner, repoName, workflowName)
	req, err := http.NewRequest("POST", url, bytes.NewReader(payloadBytes))
	if err != nil {
		fmt.Printf("Failed to create request: %v", err)
		return
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Accept", "application/vnd.github.v3+json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", githubToken))

	// Workflow Dispatchのリクエストを送信
	client := http.DefaultClient
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Failed to send request: %v", err)
		return
	}
	defer resp.Body.Close()

	// レスポンスをチェック
	if resp.StatusCode != http.StatusCreated {
		fmt.Print(url, "\n")
		fmt.Printf("Unexpected response status: %s\n", resp.Status)
		b, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(string(b))
		return
	}

	fmt.Println("Workflow Dispatch triggered successfully!")
}

func getGitHubTokenFromParameterStore(parameterPath string) (string, error) {
	// AWSセッションの作成
	sess := session.Must(session.NewSession())

	// AWS Systems Manager サービスクライアント
	ssmClient := ssm.New(sess)

	// パラメータストアからGitHubトークンを取得
	input := &ssm.GetParameterInput{
		Name:           aws.String(parameterPath),
		WithDecryption: aws.Bool(true),
	}

	result, err := ssmClient.GetParameter(input)
	if err != nil {
		return "", err
	}

	return *result.Parameter.Value, nil
}
