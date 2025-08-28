import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../widgets/experiment_card.dart';
import '../widgets/type_filter_bar.dart';

/// ホーム画面の共通ベースウィジェット
class HomeScreenBase extends StatefulWidget {
  final String title;
  final List<Experiment> experiments;
  final bool canCreateExperiment;
  final String? userName;
  final bool isWasedaUser;
  final VoidCallback onLogout;
  final VoidCallback? onCreateExperiment;
  
  const HomeScreenBase({
    super.key,
    required this.title,
    required this.experiments,
    required this.canCreateExperiment,
    required this.userName,
    required this.isWasedaUser,
    required this.onLogout,
    this.onCreateExperiment,
  });

  @override
  State<HomeScreenBase> createState() => _HomeScreenBaseState();
}

class _HomeScreenBaseState extends State<HomeScreenBase> {
  ExperimentType? _selectedType;
  
  List<Experiment> get filteredExperiments {
    if (_selectedType == null) {
      return widget.experiments;
    }
    return widget.experiments.where((e) => e.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 42, // アプリバーの高さをさらに細くする
        titleSpacing: 0, // タイトルを完全に左寄せ
        centerTitle: false, // タイトルを左寄せに配置
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          // ユーザー情報表示
          if (widget.userName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    if (widget.isWasedaUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '早稲田',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      widget.userName!.split(' ')[0], // 名前の最初の部分のみ表示
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: widget.onLogout,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      // 実験作成ボタン（権限に応じて表示）
      floatingActionButton: SizedBox(
        height: 64,
        child: FloatingActionButton.extended(
          onPressed: widget.canCreateExperiment
              ? widget.onCreateExperiment ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('実験作成機能は準備中です'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('実験募集は早稲田大学のメールアカウントでログインした方のみご利用いただけます'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
          icon: Icon(
            Icons.add,
            size: 24,
            color: widget.canCreateExperiment ? Colors.white : Colors.white70,
          ),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '実験を募集',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.canCreateExperiment ? Colors.white : Colors.white70,
                ),
              ),
              if (!widget.canCreateExperiment)
                const Text(
                  '早稲田メール限定',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          backgroundColor: widget.canCreateExperiment
              ? const Color(0xFF8E1728)
              : Colors.grey,
          elevation: widget.canCreateExperiment ? 6 : 2,
        ),
      ),
      body: Column(
        children: [
          // 種別切り替えボタン（共通コンポーネント）
          TypeFilterBar(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          
          // 実験リスト（レスポンシブグリッド）
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: filteredExperiments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '実験がありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 700, // カード最大幅を700pxに設定
                            crossAxisSpacing: 4, // 列間隔を4pxに設定
                            mainAxisSpacing: 4, // 行間隔を4pxに設定
                            mainAxisExtent: 250, // カードの固定高さを250pxに削減
                          ),
                          itemCount: filteredExperiments.length,
                          itemBuilder: (context, index) {
                            final experiment = filteredExperiments[index];
                            return ExperimentCard(experiment: experiment);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}