import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../widgets/experiment_detail_base.dart';
import '../services/demo_auth_service.dart';
import 'chat_screen_demo.dart';

/// デモ用実験詳細画面（Firebase不要）
class ExperimentDetailScreenDemo extends StatelessWidget {
  final Experiment experiment;
  final DemoAuthService? authService;

  const ExperimentDetailScreenDemo({
    super.key,
    required this.experiment,
    this.authService,
  });

  /// 質問するボタンの処理（デモ版）
  void _handleMessageButton(BuildContext context) {
    // 実験者名を取得（labNameがあればそれを使用、なければデフォルト）
    final experimenterName = experiment.labName ?? '実験者';

    // チャット画面に遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenDemo(
          otherUserName: experimenterName,
          authService: authService ?? DemoAuthService(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExperimentDetailBase(
      experiment: experiment,
      isDemo: true,
      onMessage: () async => _handleMessageButton(context),
    );
  }
}