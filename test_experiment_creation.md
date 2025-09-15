# 実験作成機能テスト手順

## 修正内容
1. postSurveyUrlController と postSurveyTemplateId フィールドを追加
2. _saveExperiment メソッドでこれらのフィールドを正しく保存するよう修正
3. アンケート設定画面で正しいコントローラーを使用するよう修正
   - 実験前: _surveyUrlController, _surveyTemplateId
   - 実験後: _postSurveyUrlController, _postSurveyTemplateId
4. SurveyTemplateSelector の不正なパラメータ (isPostSurvey) を削除

## テスト項目
1. 実験作成画面を開く
2. 必要項目を入力
3. アンケート設定タブで実験後アンケートURLを設定
4. プレビュー画面で「作成する」ボタンをクリック
5. 実験が正常に作成されることを確認

## 確認ポイント
- 「作成する」ボタンがクリック可能で反応すること
- Firestore に postSurveyUrl が保存されること
- エラーが発生しないこと

## デバッグログ
_saveExperiment メソッドに以下のデバッグログを追加済み:
- postSurveyUrl の値
- postSurveyTemplateId の値