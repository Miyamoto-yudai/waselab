import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import '../screens/support_donation_screen.dart';

/// 汎用的な支援バナーWidget
class SupportBanner extends StatefulWidget {
  final bool compact; // コンパクト表示モード
  
  const SupportBanner({
    super.key,
    this.compact = false,
  });

  @override
  State<SupportBanner> createState() => _SupportBannerState();
}

class _SupportBannerState extends State<SupportBanner> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final shouldShow = await PreferenceService.shouldShowSupportBanner();
    if (shouldShow && mounted) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
      await PreferenceService.recordSupportBannerShown();
    }
  }

  Future<void> _handleDismiss() async {
    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
    await PreferenceService.dismissSupportBanner();
  }

  Future<void> _handleNeverShow() async {
    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
    await PreferenceService.neverShowSupportBanner();
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportDonationScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    if (widget.compact) {
      // コンパクト版（マイページ等で使用）
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _navigateToSupport,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8E1728).withValues(alpha: 0.05),
                      const Color(0xFF8E1728).withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_outline,
                        size: 20,
                        color: Color(0xFF8E1728),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'サービスへのご支援',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'タップして詳細を見る',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // フルサイズ版（ホーム画面で使用）
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF8E1728).withValues(alpha: 0.08),
              const Color(0xFF8E1728).withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    size: 24,
                    color: Color(0xFF8E1728),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'このサービスは皆様の支援で成り立っています',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ご支援・開発のご依頼はこちら',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _navigateToSupport,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: const Color(0xFF8E1728),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '詳細',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onSelected: (value) {
                        if (value == 'dismiss') {
                          _handleDismiss();
                        } else if (value == 'never') {
                          _handleNeverShow();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'dismiss',
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18),
                              SizedBox(width: 8),
                              Text('後で表示', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'never',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, size: 18),
                              SizedBox(width: 8),
                              Text('今後表示しない', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}