import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/experiment_service.dart';
import '../screens/evaluation_history_screen.dart';

class UserDetailDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDetailDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends State<UserDetailDialog> {
  final AuthService _authService = AuthService();
  final ExperimentService _experimentService = ExperimentService();
  
  AppUser? _user;
  int _createdExperiments = 0;
  int _participatedExperiments = 0;
  bool _isLoading = true;
  int _completedExperiments = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      // ユーザー情報を取得
      final userDoc = await _authService.getUserDocument(widget.userId);
      if (userDoc != null && userDoc.exists) {
        // 募集した実験数を取得
        final createdExps = await _experimentService.getUserCreatedExperiments(widget.userId);
        
        // 参加した実験数を取得
        final participatedExps = await _experimentService.getUserParticipatedExperiments(widget.userId);
        
        setState(() {
          _user = AppUser.fromFirestore(userDoc);
          _createdExperiments = createdExps.length;
          _participatedExperiments = participatedExps.length;
          _completedExperiments = _user?.participatedExperiments ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAffiliation() {
    if (_user == null) return '情報なし';
    
    if (_user!.isWasedaUser) {
      String affiliation = '早稲田大学';
      if (_user!.department != null) {
        affiliation += ' ${_user!.department}';
      }
      if (_user!.grade != null) {
        affiliation += ' ${_user!.grade}';
      }
      return affiliation;
    }
    
    return '一般';
  }

  String _getUserType() {
    if (_user == null) return '不明';
    
    if (_user!.isWasedaUser) {
      // 学部情報があれば学生とみなす
      if (_user!.department != null || _user!.grade != null) {
        return '学生';
      }
      return '教職員';
    }
    
    return '一般';
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationStat(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(String label, int amount, IconData icon, Color color, {required bool isTotal}) {
    final formattedAmount = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '¥$formattedAmount',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // 画面の80%まで
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー部分（固定）
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF8E1728),
                  child: Text(
                    widget.userName.isNotEmpty ? widget.userName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getUserType(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E1728),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // コンテンツ部分（スクロール可能）
            Expanded(
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // ユーザー情報
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プロフィール',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('所属', _getAffiliation(), icon: Icons.school),
                    if (_user != null && _user!.gender != null)
                      _buildInfoRow('性別', _user!.gender!, icon: Icons.person),
                    if (_user != null && _user!.age != null)
                      _buildInfoRow('年齢', '${_user!.age}歳', icon: Icons.cake),
                    if (_user != null && _user!.bio != null && _user!.bio!.isNotEmpty)
                      _buildInfoRow('自己紹介', _user!.bio!, icon: Icons.info_outline),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 実験統計
              const Text(
                '実験統計',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '募集した実験',
                      _createdExperiments,
                      Icons.science,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '参加した実験',
                      _participatedExperiments,
                      Icons.group,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 評価統計
              if (_user != null) ...[  
                const Text(
                  '評価統計',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.05),
                        Colors.red.withValues(alpha: 0.05),
                      ],
                      stops: _user!.goodCount + _user!.badCount > 0
                          ? [_user!.goodCount / (_user!.goodCount + _user!.badCount), 
                             _user!.goodCount / (_user!.goodCount + _user!.badCount)]
                          : [0.5, 0.5],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildEvaluationStat(
                          'Good',
                          _user!.goodCount,
                          Icons.thumb_up,
                          Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildEvaluationStat(
                          'Bad',
                          _user!.badCount,
                          Icons.thumb_down,
                          Colors.red,
                        ),
                      ],
                    ),
                    if (_user!.goodCount + _user!.badCount > 0) ...[  
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _user!.goodCount / (_user!.goodCount + _user!.badCount),
                          backgroundColor: Colors.red.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.withValues(alpha: 0.6),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Good率: ${(_user!.goodCount / (_user!.goodCount + _user!.badCount) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EvaluationHistoryScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                isMyHistory: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('評価履歴を見る'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8E1728),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // 収益統計
                if (_user!.totalEarnings > 0 || _user!.monthlyEarnings > 0) ...[  
                  const Text(
                    '収益統計',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEarningsCard(
                          '総収益',
                          _user!.totalEarnings,
                          Icons.account_balance_wallet,
                          Colors.amber,
                          isTotal: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEarningsCard(
                          '今月の収益',
                          _user!.monthlyEarnings,
                          Icons.trending_up,
                          Colors.teal,
                          isTotal: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}