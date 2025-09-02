import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/experiment_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E1728)),
                ),
              )
            else ...[
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
              
              // 統計情報
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
              
              const SizedBox(height: 24),
              
              // アクション
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: チャット画面に遷移する処理を実装
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('メッセージを送る'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E1728),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}