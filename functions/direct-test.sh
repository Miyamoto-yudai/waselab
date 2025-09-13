#!/bin/bash

# Firebase Functionsの直接テスト
echo "=== GPT-5 Direct Test ==="
echo "Testing generateSurveyWithGPT function..."

# Firebase Functionsのエンドポイント
FUNCTION_URL="https://us-central1-waselab-30308.cloudfunctions.net/generateSurveyWithGPT"

# テストデータ
TEST_DATA='{
  "data": {
    "experimentInfo": {
      "title": "テスト実験：色彩心理学",
      "description": "色と感情の関係を調べる",
      "purpose": "研究目的",
      "targetAudience": "大学生",
      "expectedOutcome": "相関関係の発見"
    },
    "surveyConfig": {
      "isPreSurvey": false,
      "maxQuestions": 5
    },
    "modelConfig": {
      "modelName": "gpt-5",
      "temperature": 1,
      "maxTokens": 2000
    }
  }
}'

# cURLでテスト（認証なし版）
echo "Sending test request..."
curl -X POST "$FUNCTION_URL" \
  -H "Content-Type: application/json" \
  -d "$TEST_DATA" \
  --verbose

echo ""
echo "Test completed. Check Firebase logs for details."