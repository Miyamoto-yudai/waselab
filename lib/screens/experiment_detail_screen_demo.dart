import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../widgets/experiment_detail_base.dart';

/// デモ用実験詳細画面（Firebase不要）
class ExperimentDetailScreenDemo extends StatelessWidget {
  final Experiment experiment;

  const ExperimentDetailScreenDemo({
    super.key,
    required this.experiment,
  });

  @override
  Widget build(BuildContext context) {
    return ExperimentDetailBase(
      experiment: experiment,
      isDemo: true,
    );
  }
}