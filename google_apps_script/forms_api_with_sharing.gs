// Google Apps Script - Forms API Web App with Sharing
// このスクリプトをGoogle Apps Scriptにデプロイして使用します
// 改善版：作成したフォームに指定されたユーザーを編集者として追加

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;

    if (action === 'createForm') {
      return createFormFromTemplate(data);
    } else if (action === 'shareForm') {
      return shareFormWithUser(data);
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
        template.instructions
      ].filter(Boolean).join('\n\n');
      form.setDescription(fullDescription);
    }

    // 質問を追加
    template.questions.forEach(question => {
      addQuestionToForm(form, question);
    });

    // フォームのファイルIDを取得
    const formFile = DriveApp.getFileById(form.getId());

    // ユーザーのメールアドレスが提供されている場合、編集者として追加
    if (userEmail) {
      try {
        formFile.addEditor(userEmail);
        console.log('Added editor: ' + userEmail);
      } catch (shareError) {
        console.error('Failed to add editor: ' + shareError.toString());
        // 共有に失敗してもフォーム作成自体は成功とする
      }
    }

    // レスポンスURLを取得
    const formUrl = form.getPublishedUrl();
    const editUrl = form.getEditUrl();
    const formId = form.getId();

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      formId: formId,
      formUrl: formUrl,
      editUrl: editUrl,
      sharedWith: userEmail || null
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

// 既存のフォームに編集者を追加する関数
function shareFormWithUser(data) {
  try {
    const formId = data.formId;
    const userEmail = data.userEmail;

    if (!formId || !userEmail) {
      throw new Error('formId and userEmail are required');
    }

    const formFile = DriveApp.getFileById(formId);
    formFile.addEditor(userEmail);

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Form shared successfully',
      formId: formId,
      sharedWith: userEmail
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

// テスト用関数
function test() {
  const testData = {
    action: 'createForm',
    template: {
      title: 'テストフォーム',
      description: 'これはテストフォームです',
      questions: [
        {
          question: '名前を入力してください',
          type: 'shortText',
          required: true
        },
        {
          question: '満足度を評価してください',
          type: 'scale',
          required: true,
          scaleMin: 1,
          scaleMax: 5,
          scaleMinLabel: '不満',
          scaleMaxLabel: '満足'
        }
      ]
    },
    userEmail: 'test@example.com' // テスト用メールアドレス
  };

  const result = createFormFromTemplate(testData);
  console.log(result.getContent());
}