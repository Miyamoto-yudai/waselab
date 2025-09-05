import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_firestore_debug.dart';
import '../utils/create_test_data.dart';
import '../utils/create_test_data_v2.dart';
import '../utils/create_test_data_fixed.dart';
import '../utils/fix_existing_data.dart';

/// デバッグとテストデータ作成のための画面
class TestDebugScreen extends StatefulWidget {
  const TestDebugScreen({super.key});

  @override
  State<TestDebugScreen> createState() => _TestDebugScreenState();
}

class _TestDebugScreenState extends State<TestDebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _debugOutput = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }
  
  void _checkCurrentUser() {
    final user = _auth.currentUser;
    setState(() {
      _debugOutput = '現在のユーザー:\n';
      if (user != null) {
        _debugOutput += 'UID: ${user.uid}\n';
        _debugOutput += 'Email: ${user.email}\n';
        _debugOutput += 'DisplayName: ${user.displayName ?? "未設定"}\n';
      } else {
        _debugOutput += 'ログインしていません\n';
      }
    });
  }
  
  Future<void> _runDebugReport() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'デバッグレポート生成中...\n';
    });
    
    try {
      // 現在のユーザー情報
      await FirestoreDebugger.showCurrentUser();
      
      // すべての実験データ
      final experiments = await _firestore.collection('experiments').get();
      String output = '===== 実験データ一覧 =====\n';
      output += '総数: ${experiments.docs.length}件\n\n';
      
      for (final doc in experiments.docs) {
        final data = doc.data();
        output += '【${data['title']}】\n';
        output += '  ID: ${doc.id}\n';
        output += '  作成者ID: ${data['creatorId']}\n';
        output += '  状態: ${data['status'] ?? "未設定"}\n';
        output += '  作成日: ${(data['createdAt'] as Timestamp?)?.toDate()}\n';
        output += '\n';
      }
      
      setState(() {
        _debugOutput = output;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugOutput = 'エラー: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createTestData() async {
    // オプション選択ダイアログ
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テストデータ作成'),
        content: const Text('作成するデータを選択してください'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'simple'),
            child: const Text('シンプル(3件)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'diverse'),
            child: const Text('多様(30件)'),
          ),
        ],
      ),
    );
    
    if (option == null) return;
    
    setState(() {
      _isLoading = true;
      _debugOutput = 'テストデータ作成中...\n';
    });
    
    try {
      if (option == 'simple') {
        // 修正版を使用（正確に3件のみ作成）
        await TestDataCreatorFixed.createExactThreeExperiments();
        setState(() {
          _debugOutput = '正確に3件のテストデータを作成しました！\n';
          _debugOutput += '各実験に予約スロットも作成されました。\n';
        });
      } else {
        await TestDataCreatorV2.createDiverseExperiments(count: 30);
        setState(() {
          _debugOutput = '30件の多様なテストデータを作成しました！\n';
          _debugOutput += '各実験に予約スロットも作成されました。\n';
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // 作成後に自動で一覧を表示
      await _runDebugReport();
    } catch (e) {
      setState(() {
        _debugOutput = 'エラー: $e\n';
        _debugOutput += '\n詳細:\n${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fixExistingData() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '既存データを修復中...\n';
    });
    
    try {
      final fixedCount = await ExistingDataFixer.fixRequirementsField();
      await ExistingDataFixer.validateAllExperiments();
      
      setState(() {
        _debugOutput = '$fixedCount件のデータを修復しました。\n';
        _isLoading = false;
      });
      
      // 修復後に一覧を表示
      await _runDebugReport();
    } catch (e) {
      setState(() {
        _debugOutput = 'エラー: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteAllExperiments() async {
    // 確認ダイアログ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('すべての実験データを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
      _debugOutput = 'すべての実験データを削除中...\n';
    });
    
    try {
      int experimentCount = 0;
      int slotCount = 0;
      int errorCount = 0;
      String errors = '';
      
      // 1. experiment_slotsコレクションの削除
      _debugOutput += '予約スロットを削除中...\n';
      setState(() {});
      
      final slots = await _firestore.collection('experiment_slots').get();
      for (final doc in slots.docs) {
        try {
          await doc.reference.delete();
          slotCount++;
        } catch (e) {
          errorCount++;
          errors += 'Slot ${doc.id}: $e\n';
        }
      }
      
      _debugOutput += '  $slotCount件のスロットを削除\n';
      setState(() {});
      
      // 2. experimentsコレクションの削除
      _debugOutput += '実験データを削除中...\n';
      setState(() {});
      
      final experiments = await _firestore.collection('experiments').get();
      final currentUserId = _auth.currentUser?.uid;
      
      for (final doc in experiments.docs) {
        try {
          final data = doc.data();
          final creatorId = data['creatorId'];
          
          // 自分が作成者の実験のみ削除可能
          if (creatorId == currentUserId) {
            await doc.reference.delete();
            experimentCount++;
          } else {
            // 他人の実験はスキップ
            errors += 'Experiment ${doc.id}: 削除権限がありません（作成者: $creatorId）\n';
          }
        } catch (e) {
          errorCount++;
          errors += 'Experiment ${doc.id}: $e\n';
        }
      }
      
      setState(() {
        _debugOutput = '削除完了:\n';
        _debugOutput += '- 実験: $experimentCount件\n';
        _debugOutput += '- スロット: $slotCount件\n';
        if (errorCount > 0) {
          _debugOutput += '\nエラー: $errorCount件\n';
          _debugOutput += errors;
        }
        if (experiments.docs.length > experimentCount) {
          _debugOutput += '\n注意: ${experiments.docs.length - experimentCount}件の実験は削除権限がないためスキップされました。';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugOutput += '\nエラー: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグツール'),
        backgroundColor: Colors.red[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 警告メッセージ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'これは開発用のデバッグ画面です。\n本番環境では使用しないでください。',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 操作ボタン
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkCurrentUser,
                  icon: const Icon(Icons.person),
                  label: const Text('ユーザー確認'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runDebugReport,
                  icon: const Icon(Icons.list),
                  label: const Text('実験一覧'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestData,
                  icon: const Icon(Icons.add),
                  label: const Text('テストデータ作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fixExistingData,
                  icon: const Icon(Icons.build),
                  label: const Text('データ修復'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteAllExperiments,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('全削除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // デバッグ出力
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _debugOutput,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}