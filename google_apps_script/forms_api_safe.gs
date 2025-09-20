// Google Apps Script - Forms API (安全版)
// DriveApp.addEditorを使わない代替実装

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;

    if (action === 'createForm') {
      return createFormFromTemplate(data);
    } else {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: 'Invalid action'
      })).setMimeType(ContentService.MimeType.JSON);
    }
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function createFormFromTemplate(data) {
  try {
    const template = data.template;
    const customTitle = data.customTitle || template.title;
    const userEmail = data.userEmail; // ユーザーのメールアドレス

    // Google Formを作成
    const form = FormApp.create(customTitle);

    // フォームの説明を設定
    if (template.description || template.instructions) {
      const fullDescription = [
        template.description,
        template.instructions,
        userEmail ? `\n作成者: ${userEmail}` : '' // メールアドレスを説明に記載
      ].filter(Boolean).join('\n\n');
      form.setDescription(fullDescription);
    }

    // 質問を追加
    template.questions.forEach(question => {
      addQuestionToForm(form, question);
    });

    // レスポンスURLを取得
    const formUrl = form.getPublishedUrl();
    const editUrl = form.getEditUrl();
    const formId = form.getId();

    // 編集用URLに認証情報を付加（ユーザーが手動でアクセス時に使用）
    const editUrlWithHint = userEmail ?
      `${editUrl}#email=${encodeURIComponent(userEmail)}` : editUrl;

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      formId: formId,
      formUrl: formUrl,
      editUrl: editUrlWithHint,
      note: 'フォームが作成されました。編集するには、作成時に使用したGoogleアカウントでログインしてください。'
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function addQuestionToForm(form, question) {
  let item;

  switch (question.type) {
    case 'multipleChoice':
      item = form.addMultipleChoiceItem();
      item.setTitle(question.question);
      if (question.options) {
        item.setChoiceValues(question.options);
      }
      break;

    case 'checkbox':
      item = form.addCheckboxItem();
      item.setTitle(question.question);
      if (question.options) {
        item.setChoiceValues(question.options);
      }
      break;

    case 'scale':
      item = form.addScaleItem();
      item.setTitle(question.question);
      item.setBounds(question.scaleMin || 1, question.scaleMax || 5);
      if (question.scaleMinLabel) {
        item.setLabels(question.scaleMinLabel, question.scaleMaxLabel || '');
      }
      break;

    case 'shortText':
      item = form.addTextItem();
      item.setTitle(question.question);
      break;

    case 'longText':
      item = form.addParagraphTextItem();
      item.setTitle(question.question);
      break;

    case 'date':
      item = form.addDateItem();
      item.setTitle(question.question);
      break;

    case 'time':
      item = form.addTimeItem();
      item.setTitle(question.question);
      break;

    default:
      item = form.addTextItem();
      item.setTitle(question.question);
  }

  // 必須設定
  if (item && question.required) {
    item.setRequired(true);
  }

  // プレースホルダー（ヘルプテキスト）設定
  if (item && question.placeholder) {
    item.setHelpText(question.placeholder);
  }
}