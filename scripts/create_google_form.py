#!/usr/bin/env python3
"""
わせラボチーム - システム開発のご相談・お見積りGoogleフォーム自動作成スクリプト
"""

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
import json
import os

SCOPES = ['https://www.googleapis.com/auth/forms.body']

def create_development_consultation_form():
    """開発相談フォームを作成"""

    creds = None

    # トークンファイルが存在する場合は読み込み
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)

    # 認証が無効または存在しない場合
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # トークンを保存
        with open('token.json', 'w') as token:
            token.write(creds.to_json())

    # Forms APIサービスを構築
    service = build('forms', 'v1', credentials=creds)

    # フォームの基本構造
    form = {
        "info": {
            "title": "わせラボチーム｜システム開発のご相談・お見積り",
            "documentTitle": "わせラボ開発相談フォーム"
        }
    }

    # フォームを作成
    result = service.forms().create(body=form).execute()
    form_id = result['formId']

    print(f"フォームが作成されました: https://docs.google.com/forms/d/{form_id}/edit")

    # フォームの内容を更新
    update = {
        "requests": [
            {
                "updateFormInfo": {
                    "info": {
                        "description": (
                            "わせラボチームは、研究用システム・就活用ポートフォリオ・\n"
                            "業務効率化ツールなど、お客様のニーズに合わせた\n"
                            "オーダーメイドのシステム開発を承っております。\n\n"
                            "まずはお気軽にご相談ください。"
                        )
                    },
                    "updateMask": "description"
                }
            },
            # セクション1: 案件カテゴリ
            {
                "createItem": {
                    "item": {
                        "title": "どのようなシステムをお探しですか？",
                        "description": "開発をご希望のシステムカテゴリをお選びください",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "🔬 研究用システム・実験管理システム"},
                                        {"value": "💼 就活用ポートフォリオ・マイページ"},
                                        {"value": "📊 データ分析・可視化システム"},
                                        {"value": "🏢 業務管理・効率化システム"},
                                        {"value": "🎓 教育支援・学習管理システム"},
                                        {"value": "📱 モバイルアプリケーション"},
                                        {"value": "🌐 Webサイト・ECサイト"},
                                        {"value": "🤖 AI・機械学習システム"},
                                        {"value": "その他", "isOther": True}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 0}
                }
            },
            # セクション2: お客様情報
            {
                "createItem": {
                    "item": {
                        "title": "お客様について教えてください",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 1}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "お名前",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 2}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "フリガナ",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 3}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "ご所属",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "大学・研究機関"},
                                        {"value": "一般企業"},
                                        {"value": "スタートアップ"},
                                        {"value": "個人事業主"},
                                        {"value": "学生（研究室所属）"},
                                        {"value": "学生（個人）"},
                                        {"value": "その他", "isOther": True}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 4}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "組織名・会社名",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 5}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "部署・研究室名",
                        "description": "（任意）",
                        "questionItem": {
                            "question": {
                                "required": False,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 6}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "メールアドレス",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 7}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "電話番号",
                        "description": "（任意）",
                        "questionItem": {
                            "question": {
                                "required": False,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 8}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "希望連絡方法",
                        "description": "複数選択可",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "CHECKBOX",
                                    "options": [
                                        {"value": "メール"},
                                        {"value": "電話"},
                                        {"value": "Zoom等のオンラインミーティング"},
                                        {"value": "対面でのご相談"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 9}
                }
            },
            # セクション3: プロジェクト概要
            {
                "createItem": {
                    "item": {
                        "title": "実現したいシステムについて",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 10}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "プロジェクト名・システム名",
                        "description": "（任意）例：「〇〇管理システム」「〇〇ポートフォリオ」など",
                        "questionItem": {
                            "question": {
                                "required": False,
                                "textQuestion": {
                                    "paragraph": False
                                }
                            }
                        }
                    },
                    "location": {"index": 11}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "解決したい課題",
                        "description": (
                            "例：\n"
                            "・研究データの管理が煩雑で時間がかかっている\n"
                            "・就活用に自分の作品をまとめたサイトが欲しい\n"
                            "・顧客管理を効率化したい"
                        ),
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": True
                                }
                            }
                        }
                    },
                    "location": {"index": 12}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "システムに求める主要機能",
                        "description": (
                            "例：\n"
                            "・実験参加者の予約管理機能\n"
                            "・作品のギャラリー表示機能\n"
                            "・売上データの自動集計機能"
                        ),
                        "questionItem": {
                            "question": {
                                "required": True,
                                "textQuestion": {
                                    "paragraph": True
                                }
                            }
                        }
                    },
                    "location": {"index": 13}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "想定利用者数",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "1-10名"},
                                        {"value": "11-50名"},
                                        {"value": "51-100名"},
                                        {"value": "101-500名"},
                                        {"value": "501名以上"},
                                        {"value": "不明・これから検討"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 14}
                }
            },
            # セクション4: 技術的な要望
            {
                "createItem": {
                    "item": {
                        "title": "技術面でのご要望",
                        "description": "技術的な詳細がわからない場合はスキップ可能です",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 15}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "必須機能",
                        "description": "必要な機能をお選びください（複数選択可）",
                        "questionItem": {
                            "question": {
                                "required": False,
                                "choiceQuestion": {
                                    "type": "CHECKBOX",
                                    "options": [
                                        {"value": "ユーザーログイン・認証機能"},
                                        {"value": "データベース管理"},
                                        {"value": "ファイルアップロード・管理"},
                                        {"value": "メール自動送信"},
                                        {"value": "決済機能"},
                                        {"value": "SNS連携"},
                                        {"value": "スマートフォン対応（レスポンシブ）"},
                                        {"value": "多言語対応"},
                                        {"value": "データエクスポート（Excel/CSV）"},
                                        {"value": "リアルタイム更新"},
                                        {"value": "API連携"},
                                        {"value": "分析・レポート機能"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 16}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "デザインの重要度",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "scaleQuestion": {
                                    "low": 1,
                                    "high": 5,
                                    "lowLabel": "機能重視でシンプルでOK",
                                    "highLabel": "非常にデザインにこだわりたい"
                                }
                            }
                        }
                    },
                    "location": {"index": 17}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "参考にしたいサイト・システム",
                        "description": "（任意）似たようなシステムのURLがあれば教えてください",
                        "questionItem": {
                            "question": {
                                "required": False,
                                "textQuestion": {
                                    "paragraph": True
                                }
                            }
                        }
                    },
                    "location": {"index": 18}
                }
            },
            # セクション5: 予算とスケジュール
            {
                "createItem": {
                    "item": {
                        "title": "ご予算と納期について",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 19}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "ご予算",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "💰 10万円以下"},
                                        {"value": "💰 10-30万円"},
                                        {"value": "💰 30-50万円"},
                                        {"value": "💰 50-100万円"},
                                        {"value": "💰 100-200万円"},
                                        {"value": "💰 200-500万円"},
                                        {"value": "💰 500万円以上"},
                                        {"value": "🤝 相談して決めたい"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 20}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "希望納期",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "⚡ お急ぎ（1ヶ月以内）"},
                                        {"value": "📅 2-3ヶ月"},
                                        {"value": "📅 3-6ヶ月"},
                                        {"value": "📅 6ヶ月-1年"},
                                        {"value": "🤝 相談して決めたい"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 21}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "開発開始希望時期",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "すぐにでも開始したい"},
                                        {"value": "1ヶ月以内"},
                                        {"value": "2-3ヶ月以内"},
                                        {"value": "半年以内"},
                                        {"value": "未定・相談したい"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 22}
                }
            },
            # セクション6: 運用・保守
            {
                "createItem": {
                    "item": {
                        "title": "システム完成後について",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 23}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "運用保守サポート",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "必要（月額サポート希望）"},
                                        {"value": "不要（納品のみでOK）"},
                                        {"value": "相談して決めたい"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 24}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "将来的な機能追加",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "積極的に追加していきたい"},
                                        {"value": "必要に応じて追加したい"},
                                        {"value": "現時点では考えていない"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 25}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "操作マニュアル",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "RADIO",
                                    "options": [
                                        {"value": "詳細なマニュアルが必要"},
                                        {"value": "簡易的なマニュアルでOK"},
                                        {"value": "不要"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 26}
                }
            },
            # セクション7: 追加情報
            {
                "createItem": {
                    "item": {
                        "title": "その他お聞かせください",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 27}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "その他ご要望・ご質問",
                        "description": (
                            "（任意）\n"
                            "例：\n"
                            "・特定の技術（React、Flutter等）を使ってほしい\n"
                            "・セキュリティ面で特に配慮が必要\n"
                            "・段階的なリリースを希望"
                        ),
                        "questionItem": {
                            "question": {
                                "required": False,
                                "textQuestion": {
                                    "paragraph": True
                                }
                            }
                        }
                    },
                    "location": {"index": 28}
                }
            },
            # セクション8: 確認事項
            {
                "createItem": {
                    "item": {
                        "title": "最後にご確認ください",
                        "pageBreakItem": {}
                    },
                    "location": {"index": 29}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "プライバシーポリシーへの同意",
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "CHECKBOX",
                                    "options": [
                                        {"value": "個人情報の取り扱いについて同意します"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 30}
                }
            },
            {
                "createItem": {
                    "item": {
                        "title": "今後の流れの確認",
                        "description": (
                            "1. フォーム送信後、2営業日以内にご連絡\n"
                            "2. 詳細ヒアリング（オンライン/対面）\n"
                            "3. お見積り・提案書の提出\n"
                            "4. ご契約・開発開始"
                        ),
                        "questionItem": {
                            "question": {
                                "required": True,
                                "choiceQuestion": {
                                    "type": "CHECKBOX",
                                    "options": [
                                        {"value": "上記の流れを理解しました"}
                                    ]
                                }
                            }
                        }
                    },
                    "location": {"index": 31}
                }
            }
        ]
    }

    # バッチアップデートを実行
    service.forms().batchUpdate(formId=form_id, body=update).execute()

    print("フォームの設定が完了しました！")
    print(f"編集用URL: https://docs.google.com/forms/d/{form_id}/edit")
    print(f"回答用URL: https://docs.google.com/forms/d/e/{form_id}/viewform")

    return form_id

if __name__ == "__main__":
    try:
        form_id = create_development_consultation_form()
        print("\n✅ フォームの作成が成功しました！")

        # URLを保存
        with open('form_urls.txt', 'w') as f:
            f.write(f"フォームID: {form_id}\n")
            f.write(f"編集用URL: https://docs.google.com/forms/d/{form_id}/edit\n")
            f.write(f"回答用URL: https://docs.google.com/forms/d/e/{form_id}/viewform\n")

    except Exception as e:
        print(f"❌ エラーが発生しました: {str(e)}")
        print("\n以下を確認してください：")
        print("1. Google Cloud Consoleで Forms API が有効になっているか")
        print("2. credentials.json ファイルが存在するか")
        print("3. 適切な権限（forms.body スコープ）があるか")