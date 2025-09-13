/**
 * Google Forms Template Manager
 * このスクリプトをGoogle Apps Scriptにデプロイして、
 * Webアプリケーションとして公開することで、
 * FlutterアプリからHTTP経由でGoogleフォームを自動作成できます。
 */

// テンプレートフォームのIDを管理
const TEMPLATE_FORMS = {
  'basic_demographics': '1ABC...', // 実際のGoogle Form IDに置き換える
  'health_check': '1DEF...',
  'psychology_scale': '1GHI...',
  'cognitive_evaluation': '1JKL...',
  'ux_evaluation': '1MNO...',
  'behavioral_observation': '1PQR...',
  'informed_consent': '1STU...',
};

/**
 * GET リクエストの処理
 */
function doGet(e) {
  const params = e.parameter;
  const action = params.action || 'list';
  
  try {
    switch (action) {
      case 'list':
        return createJsonResponse(listTemplates());
      case 'create':
        return createJsonResponse(createFromTemplate(params));
      default:
        return createErrorResponse('Invalid action');
    }
  } catch (error) {
    return createErrorResponse(error.toString());
  }
}

/**
 * POST リクエストの処理
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const action = data.action;
    
    switch (action) {
      case 'createFromJson':
        return createJsonResponse(createFormFromJson(data));
      case 'cloneTemplate':
        return createJsonResponse(cloneTemplateForm(data));
      default:
        return createErrorResponse('Invalid action');
    }
  } catch (error) {
    return createErrorResponse(error.toString());
  }
}

/**
 * テンプレート一覧を返す
 */
function listTemplates() {
  const templates = [];
  
  for (const [key, formId] of Object.entries(TEMPLATE_FORMS)) {
    try {
      const form = FormApp.openById(formId);
      templates.push({
        id: key,
        formId: formId,
        title: form.getTitle(),
        description: form.getDescription(),
        url: form.getPublishedUrl()
      });
    } catch (e) {
      // フォームが存在しない場合はスキップ
      console.log(`Template ${key} not found: ${e}`);
    }
  }
  
  return {
    success: true,
    templates: templates
  };
}

/**
 * テンプレートからフォームを作成
 */
function createFromTemplate(params) {
  const templateId = params.templateId;
  const title = params.title || 'New Form';
  const description = params.description || '';
  
  if (!TEMPLATE_FORMS[templateId]) {
    throw new Error('Template not found: ' + templateId);
  }
  
  try {
    // テンプレートフォームを開く
    const templateForm = FormApp.openById(TEMPLATE_FORMS[templateId]);
    
    // 新しいフォームを作成
    const newForm = FormApp.create(title);
    newForm.setDescription(description);
    
    // テンプレートから質問をコピー
    const items = templateForm.getItems();
    for (const item of items) {
      copyItemToForm(item, newForm);
    }
    
    // 設定をコピー
    newForm.setCollectEmail(templateForm.collectsEmail());
    newForm.setRequireLogin(templateForm.requiresLogin());
    newForm.setConfirmationMessage(templateForm.getConfirmationMessage());
    
    return {
      success: true,
      formId: newForm.getId(),
      editUrl: newForm.getEditUrl(),
      publishedUrl: newForm.getPublishedUrl()
    };
    
  } catch (error) {
    throw new Error('Failed to create form: ' + error.toString());
  }
}

/**
 * JSONデータからフォームを作成
 */
function createFormFromJson(data) {
  const formData = data.formData;
  
  try {
    // 新しいフォームを作成
    const form = FormApp.create(formData.title || 'New Form');
    form.setDescription(formData.description || '');
    
    if (formData.confirmationMessage) {
      form.setConfirmationMessage(formData.confirmationMessage);
    }
    
    // 質問項目を追加
    if (formData.items && Array.isArray(formData.items)) {
      for (const itemData of formData.items) {
        addItemFromJson(form, itemData);
      }
    }
    
    return {
      success: true,
      formId: form.getId(),
      editUrl: form.getEditUrl(),
      publishedUrl: form.getPublishedUrl()
    };
    
  } catch (error) {
    throw new Error('Failed to create form from JSON: ' + error.toString());
  }
}

/**
 * テンプレートフォームをクローン
 */
function cloneTemplateForm(data) {
  const sourceFormId = data.sourceFormId || TEMPLATE_FORMS[data.templateId];
  const newTitle = data.title || 'Cloned Form';
  
  if (!sourceFormId) {
    throw new Error('Source form ID not provided');
  }
  
  try {
    // ソースフォームを開く
    const sourceForm = FormApp.openById(sourceFormId);
    
    // DriveApp を使用してフォームをコピー
    const sourceFile = DriveApp.getFileById(sourceFormId);
    const copiedFile = sourceFile.makeCopy(newTitle);
    const newFormId = copiedFile.getId();
    
    // コピーされたフォームを開いて情報を取得
    const newForm = FormApp.openById(newFormId);
    
    // カスタマイズがあれば適用
    if (data.description) {
      newForm.setDescription(data.description);
    }
    
    return {
      success: true,
      formId: newFormId,
      editUrl: newForm.getEditUrl(),
      publishedUrl: newForm.getPublishedUrl()
    };
    
  } catch (error) {
    throw new Error('Failed to clone form: ' + error.toString());
  }
}

/**
 * フォームアイテムをコピー
 */
function copyItemToForm(sourceItem, targetForm) {
  const type = sourceItem.getType();
  const title = sourceItem.getTitle();
  const helpText = sourceItem.getHelpText();
  
  let newItem;
  
  switch (type) {
    case FormApp.ItemType.TEXT:
      newItem = targetForm.addTextItem();
      break;
      
    case FormApp.ItemType.PARAGRAPH_TEXT:
      newItem = targetForm.addParagraphTextItem();
      break;
      
    case FormApp.ItemType.MULTIPLE_CHOICE:
      const mcItem = sourceItem.asMultipleChoiceItem();
      newItem = targetForm.addMultipleChoiceItem();
      newItem.setChoices(mcItem.getChoices());
      break;
      
    case FormApp.ItemType.CHECKBOX:
      const cbItem = sourceItem.asCheckboxItem();
      newItem = targetForm.addCheckboxItem();
      newItem.setChoices(cbItem.getChoices());
      break;
      
    case FormApp.ItemType.SCALE:
      const scaleItem = sourceItem.asScaleItem();
      newItem = targetForm.addScaleItem();
      newItem.setBounds(scaleItem.getLowerBound(), scaleItem.getUpperBound());
      const leftLabel = scaleItem.getLeftLabel();
      const rightLabel = scaleItem.getRightLabel();
      if (leftLabel) newItem.setLabels(leftLabel, rightLabel || '');
      break;
      
    case FormApp.ItemType.DATE:
      newItem = targetForm.addDateItem();
      break;
      
    case FormApp.ItemType.TIME:
      newItem = targetForm.addTimeItem();
      break;
      
    case FormApp.ItemType.SECTION_HEADER:
      newItem = targetForm.addSectionHeaderItem();
      break;
      
    default:
      // サポートされていないタイプはスキップ
      return;
  }
  
  if (newItem) {
    newItem.setTitle(title);
    if (helpText) {
      newItem.setHelpText(helpText);
    }
    
    // 必須設定をコピー
    if (sourceItem.isRequired && sourceItem.isRequired()) {
      newItem.setRequired(true);
    }
  }
}

/**
 * JSONデータからアイテムを追加
 */
function addItemFromJson(form, itemData) {
  const title = itemData.title || '';
  const description = itemData.description || '';
  const required = itemData.required || false;
  
  if (!itemData.questionItem || !itemData.questionItem.question) {
    return;
  }
  
  const question = itemData.questionItem.question;
  let item;
  
  if (question.choiceQuestion) {
    const choiceQ = question.choiceQuestion;
    
    if (choiceQ.type === 'RADIO') {
      item = form.addMultipleChoiceItem();
      const choices = choiceQ.options.map(opt => 
        item.createChoice(opt.value)
      );
      item.setChoices(choices);
    } else if (choiceQ.type === 'CHECKBOX') {
      item = form.addCheckboxItem();
      const choices = choiceQ.options.map(opt => 
        item.createChoice(opt.value)
      );
      item.setChoices(choices);
    }
    
  } else if (question.scaleQuestion) {
    const scaleQ = question.scaleQuestion;
    item = form.addScaleItem();
    item.setBounds(scaleQ.low || 1, scaleQ.high || 5);
    if (scaleQ.lowLabel || scaleQ.highLabel) {
      item.setLabels(scaleQ.lowLabel || '', scaleQ.highLabel || '');
    }
    
  } else if (question.textQuestion) {
    if (question.textQuestion.paragraph) {
      item = form.addParagraphTextItem();
    } else {
      item = form.addTextItem();
    }
    
  } else if (question.dateQuestion) {
    item = form.addDateItem();
    
  } else if (question.timeQuestion) {
    item = form.addTimeItem();
  }
  
  if (item) {
    item.setTitle(title);
    if (description) {
      item.setHelpText(description);
    }
    if (required) {
      item.setRequired(true);
    }
  }
}

/**
 * JSON レスポンスを作成
 */
function createJsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * エラーレスポンスを作成
 */
function createErrorResponse(message) {
  return createJsonResponse({
    success: false,
    error: message
  });
}

/**
 * テスト用関数
 */
function testCreateForm() {
  const result = createFormFromJson({
    formData: {
      title: 'Test Form',
      description: 'This is a test form',
      items: [
        {
          title: 'What is your name?',
          questionItem: {
            question: {
              required: true,
              textQuestion: {
                paragraph: false
              }
            }
          }
        },
        {
          title: 'How satisfied are you?',
          questionItem: {
            question: {
              required: true,
              scaleQuestion: {
                low: 1,
                high: 5,
                lowLabel: 'Not satisfied',
                highLabel: 'Very satisfied'
              }
            }
          }
        }
      ]
    }
  });
  
  console.log(result);
}