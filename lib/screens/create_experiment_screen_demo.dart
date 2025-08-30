import 'package:flutter/material.dart';
import '../widgets/create_experiment_base.dart';

/// デモ用実験作成画面
class CreateExperimentScreenDemo extends StatelessWidget {
  const CreateExperimentScreenDemo({super.key});

  Future<void> _handleSave(Map<String, dynamic> data) async {
    // デモモードでは実際には保存しない
    // 2秒の遅延を入れて保存処理をシミュレート
    await Future.delayed(const Duration(seconds: 2));
    
    // デバッグ出力
    print('デモモード: 実験データ（実際には保存されません）');
    print('タイトル: ${data['title']}');
    print('説明: ${data['description']}');
    print('タイプ: ${data['type']}');
    print('報酬: ${data['isPaid'] ? '¥${data['reward']}' : '無償'}');
    print('場所: ${data['location']}');
    print('柔軟な日程調整: ${data['allowFlexibleSchedule']}');
    
    // 成功を返す
    return;
  }

  @override
  Widget build(BuildContext context) {
    return CreateExperimentBase(
      isDemo: true,
      onSave: _handleSave,
    );
  }
}