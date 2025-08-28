import 'package:flutter/material.dart';
import '../models/experiment.dart';

/// 実験種別フィルターバーの共通ウィジェット
class TypeFilterBar extends StatelessWidget {
  final ExperimentType? selectedType;
  final Function(ExperimentType?) onTypeSelected;
  
  const TypeFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  /// 実験種別のアイコンを取得
  IconData _getTypeIcon(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Icons.computer;
      case ExperimentType.onsite:
        return Icons.location_on;
      case ExperimentType.survey:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 画面幅いっぱいに広げる
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8E1728),
            const Color(0xFF7F3143),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E1728).withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width, // 最小幅を画面幅に設定
          ),
          child: Row(
            children: [
              // すべてボタン
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: selectedType == null 
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => onTypeSelected(null),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(
                        'すべて',
                        style: TextStyle(
                          fontWeight: selectedType == null ? FontWeight.bold : FontWeight.w500,
                          color: selectedType == null 
                            ? const Color(0xFF8E1728)
                            : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 各種別ボタン
              ...ExperimentType.values.map((type) {
                final isSelected = selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected 
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => onTypeSelected(isSelected ? null : type),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(type),
                              size: 16,
                              color: isSelected 
                                ? const Color(0xFF8E1728)
                                : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected 
                                  ? const Color(0xFF8E1728)
                                  : Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}