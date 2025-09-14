import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';
import '../models/experiment_reservation.dart';
import '../models/app_user.dart';
import '../models/notification.dart';
import '../services/reservation_service.dart';
import '../services/experiment_service.dart';
import '../services/notification_service.dart';
import '../services/google_calendar_service.dart';
import '../widgets/experiment_calendar_view.dart';
import '../widgets/custom_circle_avatar.dart';
import '../models/avatar_design.dart';
import '../models/avatar_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/preference_service.dart';
import 'chat_screen.dart';
import 'support_donation_screen.dart';

/// 実験詳細画面
/// 選択された実験の詳細情報を表示する
class ExperimentDetailScreen extends StatefulWidget {
  final Experiment experiment;
  final bool isMyExperiment;

  const ExperimentDetailScreen({
    super.key,
    required this.experiment,
    this.isMyExperiment = false,
  });

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageService _messageService = MessageService();
  final AuthService _authService = AuthService();
  final ExperimentService _experimentService = ExperimentService();
  final UserService _userService = UserService();
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  bool _showCalendar = false;
  bool _isLoading = false;
  bool _isParticipating = false;
  String? _experimenterName;
  ExperimentReservation? _currentUserReservation;
  ExperimentSlot? _reservedSlot;
  late List<bool> _detailConsentChecked;

  @override
  void initState() {
    super.initState();
    // 同意項目のチェック状態を初期化
    _detailConsentChecked = List.filled(widget.experiment.consentItems.length, false);
    // デバッグ: consentItemsの内容を確認
    debugPrint('=== ExperimentDetailScreen: consentItems確認 ===');
    debugPrint('実験タイトル: ${widget.experiment.title}');
    debugPrint('consentItems数: ${widget.experiment.consentItems.length}');
    debugPrint('consentItems内容: ${widget.experiment.consentItems}');
    debugPrint('=======================================');
    _checkParticipation();
    _loadExperimenterName();
    _loadUserReservation();
  }

  /// 実験者の名前を取得
  Future<void> _loadExperimenterName() async {
    final user = await _userService.getUser(widget.experiment.creatorId);
    if (user != null && mounted) {
      setState(() {
        _experimenterName = user.name;
      });
    }
  }

  /// ユーザーが既に参加しているかチェック
  Future<void> _checkParticipation() async {
    final user = _auth.currentUser;
    if (user != null) {
      final participating = await _experimentService.isUserParticipating(
        widget.experiment.id,
        user.uid,
      );
      if (mounted) {
        setState(() {
          _isParticipating = participating;
        });
      }
    }
  }

  /// ユーザーの予約情報を取得
  Future<void> _loadUserReservation() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final reservationsStream = _reservationService.getUserReservations(user.uid);
        final reservations = await reservationsStream.first;
        
        // この実験に対する予約を検索
        final reservation = reservations.firstWhere(
          (r) => r.experimentId == widget.experiment.id && r.status == ReservationStatus.confirmed,
          orElse: () => ExperimentReservation(
            id: '',
            userId: '',
            experimentId: '',
            slotId: '',
            reservedAt: DateTime.now(),
            status: ReservationStatus.cancelled,
          ),
        );
        
        if (reservation.id.isNotEmpty && mounted) {
          // スロット情報を取得
          try {
            final slotDoc = await _reservationService.getSlotById(reservation.slotId);
            setState(() {
              _currentUserReservation = reservation;
              _reservedSlot = slotDoc;
            });
          } catch (e) {
            // スロット情報が取得できない場合は予約情報のみ保持
            debugPrint('スロット情報の取得エラー（無視）: $e');
            setState(() {
              _currentUserReservation = reservation;
            });
          }
        }
      }
    } catch (e) {
      // 予約情報が取得できなくても実験詳細は表示する
      debugPrint('予約情報の取得エラー（無視）: $e');
    }
  }

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

  /// 実験種別の色を取得
  Color _getTypeColor(ExperimentType type) {
    switch (type) {
      case ExperimentType.online:
        return Colors.blue;
      case ExperimentType.onsite:
        return Colors.green;
      case ExperimentType.survey:
        return Colors.orange;
    }
  }

  /// 日時のフォーマット
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未定';
    
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$year年$month月$day日 $hour:$minute';
  }

  /// 日付のフォーマット
  String _formatDate(DateTime? date) {
    if (date == null) return '未定';
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  /// スロット選択時の処理
  Future<void> _handleSlotSelection(ExperimentSlot slot) async {
    // 予約確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _ReservationConfirmDialog(
          experiment: widget.experiment,
          slot: slot,
        );
      },
    );

    if (confirmed == true) {
      await _makeReservation(slot);
    }
  }

  /// 事前アンケートダイアログを表示
  Future<void> _showPreSurveyDialogForReservation(String surveyUrl) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fact_check, color: Colors.purple),
            SizedBox(width: 8),
            Text('事前アンケートのお願い'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('実験参加前に事前アンケートへの回答をお願いします。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アンケートURL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    surveyUrl,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: surveyUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URLをコピーしました'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('URLをコピー'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(surveyUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('開く'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// URLなしアンケート参加完了ダイアログ
  Future<void> _showNoUrlDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('参加完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('アンケートへの参加申請が完了しました。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '実験者からの連絡をお待ちください',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '個別チャットでアンケートの詳細が送られます',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '質問がある場合は「質問する」ボタンから実験者に連絡できます',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// アンケートURL表示ダイアログ
  Future<void> _showSurveyUrlDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('参加完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('アンケートへの参加が完了しました。\n以下のURLからアンケートに回答してください。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'アンケートURL:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.experiment.surveyUrl ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.experiment.surveyUrl ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URLをコピーしました'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('コピー'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(widget.experiment.surveyUrl ?? '');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('開く'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '回答後、実験者からの連絡をお待ちください',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 事前アンケート案内ダイアログ
  Future<void> _showPreSurveyDialog(Experiment experiment) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('参加完了'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('実験への参加申請が完了しました。'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, size: 20, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '事前アンケートに回答してください',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '参加前に必要な情報を確認させていただきます。',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'URL:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            experiment.preSurveyUrl ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: experiment.preSurveyUrl ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('URLをコピーしました'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('コピー'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple.shade700,
                              side: BorderSide(color: Colors.purple.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(experiment.preSurveyUrl ?? '');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('開く'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '実験終了後は必ず相互評価をお願いします',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// カレンダー連携プロンプトを表示
  Future<bool> _showCalendarPromptDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            SizedBox(width: 8),
            Text('Googleカレンダー連携'),
          ],
        ),
        content: const Text(
          '実験の予約をGoogleカレンダーに自動で追加しますか？\n\n'
          '連携すると、予約した実験の日時が自動でカレンダーに登録され、'
          'リマインダーも設定されます。\n\n'
          '（後から設定画面で変更できます）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('今はしない'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('連携する'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// カレンダー連携を有効化
  Future<void> _enableCalendarIntegration() async {
    try {
      setState(() => _isLoading = true);
      
      final hasPermission = await _calendarService.requestCalendarPermission();
      if (hasPermission) {
        await _calendarService.setCalendarEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Googleカレンダーと連携しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('カレンダー連携がキャンセルされました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('カレンダー連携エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カレンダー連携に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// 予約を実行
  Future<void> _makeReservation(ExperimentSlot slot) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
      }

      // 募集人数上限チェック
      if (widget.experiment.maxParticipants != null &&
          widget.experiment.participants.length >= widget.experiment.maxParticipants!) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('募集人数に達したため、予約できません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 既に予約しているかチェック
      final hasReserved = await _reservationService.hasUserReserved(
        user.uid,
        widget.experiment.id,
      );

      if (hasReserved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('既にこの実験に予約済みです'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // 初回予約かつカレンダー連携が無効の場合、プロンプトを表示
      final isFirstReservation = await PreferenceService.isFirstReservation();
      final calendarEnabled = await _calendarService.isCalendarEnabled();
      final hasShownPrompt = await PreferenceService.hasShownCalendarPrompt();
      
      if (isFirstReservation && !calendarEnabled && !hasShownPrompt && mounted) {
        await PreferenceService.recordCalendarPromptShown();
        final shouldEnableCalendar = await _showCalendarPromptDialog();
        if (shouldEnableCalendar) {
          await _enableCalendarIntegration();
        }
      }

      // 予約を作成
      final reservationId = await _reservationService.createReservation(
        userId: user.uid,
        experimentId: widget.experiment.id,
        slotId: slot.id,
      );
      
      // 初回予約を記録
      if (isFirstReservation) {
        await PreferenceService.recordFirstReservation();
      }

      // 実験への参加履歴を追加
      final experimentService = ExperimentService();
      await experimentService.joinExperiment(widget.experiment.id, user.uid);

      // 参加状態を更新
      setState(() {
        _isParticipating = true;
        _showCalendar = false;
      });

      // 予約情報を再読み込み
      await _loadUserReservation();
      
      // Googleカレンダーに登録（エラーが起きても予約処理は続行）
      if (await _calendarService.isCalendarEnabled()) {
        try {
          final eventId = await _calendarService.addReservationToCalendar(
            experiment: widget.experiment,
            slot: slot,
            reservationId: reservationId,
          );
          
          if (eventId != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Googleカレンダーに予定を追加しました'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('カレンダー登録エラー: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予約が完了しました。実験終了後は必ず相互評価をお願いします'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        // 事前アンケートがある場合、URLを表示
        if (widget.experiment.preSurveyUrl != null) {
          await _showPreSurveyDialogForReservation(widget.experiment.preSurveyUrl!);
        }
        
        // 実験完了回数を増やす
        await PreferenceService.incrementExperimentCompletedCount();
        
        // 3回以上完了している場合、支援メッセージを表示
        if (await PreferenceService.hasCompletedMultipleExperiments()) {
          _showSupportMessage();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予約に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 直接応募（固定日時の場合）
  Future<void> _handleDirectApplication() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 募集人数上限チェック
      if (widget.experiment.maxParticipants != null &&
          widget.experiment.participants.length >= widget.experiment.maxParticipants!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('募集人数に達したため、参加できません'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // アンケートタイプの場合は特別な処理
      if (widget.experiment.type == ExperimentType.survey) {
        // アンケート参加確認ダイアログ
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _SurveyParticipationDialog(
            experiment: widget.experiment,
          ),
        );

        if (confirmed != true) return;

        // 参加処理
        setState(() => _isLoading = true);
        
        final experimentService = ExperimentService();
        await experimentService.joinExperiment(widget.experiment.id, user.uid);
        
        setState(() {
          _isLoading = false;
          _isParticipating = true;
        });

        // アンケートURLがある場合のみダイアログを表示
        if (mounted) {
          if (widget.experiment.surveyUrl != null) {
            await _showSurveyUrlDialog();
          } else {
            // URLがない場合はチャットでの連絡を案内
            await _showNoUrlDialog();
          }
        }
        return;
      }

      // 通常の実験の場合の確認ダイアログ（同意項目にもチェックが必要だが、画面上でチェック済みの状態で確認）
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _DirectApplicationDialog(
          experiment: widget.experiment,
        ),
      );

      if (confirmed != true) return;

      // 参加申請処理
      setState(() => _isLoading = true);
      
      final experimentService = ExperimentService();
      await experimentService.joinExperiment(widget.experiment.id, user.uid);
      
      setState(() {
        _isLoading = false;
        _isParticipating = true;
      });

      if (mounted) {
        // 事前アンケートがある場合はダイアログを表示
        if (widget.experiment.preSurveyUrl != null && widget.experiment.preSurveyUrl!.isNotEmpty) {
          await _showPreSurveyDialog(widget.experiment);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('実験への参加申請が完了しました。実験終了後は必ず相互評価をお願いします'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('参加申請エラー: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        String errorMessage = '参加申請に失敗しました';
        
        if (e.toString().contains('自分が募集した')) {
          errorMessage = '自分が募集した実験には参加できません';
        } else if (e.toString().contains('すでに')) {
          errorMessage = 'すでにこの実験に参加しています';
        } else if (e.toString().contains('権限')) {
          errorMessage = '権限がありません。ログインし直してください';
        } else if (e.toString().contains('見つかりません')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          // 詳細なエラーメッセージを表示
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  void _showSupportMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.celebration,
              color: Color(0xFF8E1728),
            ),
            SizedBox(width: 8),
            Text('実験参加ありがとうございます！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'わせラボをご利用いただき、誠にありがとうございます。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E1728).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8E1728).withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💖 サービスへのご支援について',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'このサービスは皆様の支援の元無償で成り立っています。'
                    'ご支援いただけると大変励みになります。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportDonationScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8E1728),
            ),
            child: const Text('詳しく見る'),
          ),
        ],
      ),
    );
  }

  /// 質問するボタンの処理
  Future<void> _handleMessageButton() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインが必要です'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 現在のユーザー情報を取得
      final currentUser = await _authService.getCurrentAppUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報の取得に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 実験者名を取得（labNameがあればそれを使用、なければデフォルト）
      final experimenterName = widget.experiment.labName ?? '実験者';

      // 既存の会話を確認または新規作成
      final conversationId = await _messageService.getOrCreateConversation(
        user.uid,
        widget.experiment.creatorId,
        currentUser.name,
        experimenterName,
      );

      if (mounted) {
        // チャット画面に遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: widget.experiment.creatorId,
              otherUserName: experimenterName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('実験詳細'),
      ),
      floatingActionButton: widget.isMyExperiment
          ? null // 自分の実験の場合はFABを表示しない
          : FloatingActionButton.extended(
              onPressed: _handleMessageButton,
              backgroundColor: const Color(0xFF8E1728),
              icon: const Icon(Icons.message, color: Colors.white),
        label: const Text(
          '質問する',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        tooltip: '実験者に質問',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 自分の実験かつ募集中または進行中の場合のみバナーを表示
            if (widget.isMyExperiment && 
                (widget.experiment.status == ExperimentStatus.recruiting || 
                 widget.experiment.status == ExperimentStatus.ongoing))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E1728).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8E1728).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF8E1728),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.experiment.status == ExperimentStatus.recruiting 
                              ? 'あなたが募集中の実験'
                              : 'あなたが実施中の実験',
                            style: const TextStyle(
                              color: Color(0xFF8E1728),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '参加者数: ${widget.experiment.participants.length ?? 0}名',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // 今後実装: 参加者管理画面への遷移
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('参加者管理機能は開発中です'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.people,
                        size: 18,
                      ),
                      label: const Text('管理'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8E1728),
                      ),
                    ),
                  ],
                ),
              ),
            // タイトル
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(widget.experiment.type),
                          color: _getTypeColor(widget.experiment.type),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.experiment.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 種別タグ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(widget.experiment.type).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.experiment.type.label,
                            style: TextStyle(
                              color: _getTypeColor(widget.experiment.type),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 有償/無償タグ
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.experiment.isPaid 
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.experiment.isPaid ? '有償' : '無償',
                            style: TextStyle(
                              color: widget.experiment.isPaid 
                                ? Colors.amber[700] 
                                : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 基本情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '基本情報',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_experimenterName != null) ...[
                      FutureBuilder<AppUser?>(
                        future: _userService.getUserById(widget.experiment.creatorId),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          return Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CustomCircleAvatar(
                                  frameId: user?.selectedFrame,
                                  radius: 10,
                                  backgroundColor: user?.selectedColor != null
                                      ? AvatarColors.getById(user!.selectedColor!).color
                                      : const Color(0xFF8E1728),
                                  designBuilder: user?.selectedDesign != null && user?.selectedDesign != 'default'
                                      ? AvatarDesigns.getById(user!.selectedDesign!).builder
                                      : null,
                                  child: user?.selectedDesign == null || user?.selectedDesign == 'default'
                                      ? Text(
                                          user?.name.isNotEmpty == true 
                                            ? user!.name[0].toUpperCase() 
                                            : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '実験者: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _experimenterName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildInfoRow(
                      Icons.monetization_on,
                      '報酬',
                      widget.experiment.isPaid ? '¥${widget.experiment.reward}' : 'なし',
                      Colors.amber,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      '場所',
                      widget.experiment.location,
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    // アンケート情報の表示
                    if (widget.experiment.preSurveyUrl != null ||
                        widget.experiment.postSurveyUrl != null ||
                        (widget.experiment.surveyUrl != null && widget.experiment.type == ExperimentType.survey)) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 事前アンケート
                          if (widget.experiment.preSurveyUrl != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fact_check, size: 14, color: Colors.purple.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '実験前アンケートあり',
                                    style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          // 実験アンケート（アンケートタイプの実験用）
                          if (widget.experiment.surveyUrl != null && widget.experiment.type == ExperimentType.survey)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.assignment, size: 14, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'アンケート実施',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          // 実験後アンケート
                          if (widget.experiment.postSurveyUrl != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.quiz, size: 14, color: Colors.indigo.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '実験後アンケートあり',
                                    style: TextStyle(fontSize: 12, color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.experiment.allowFlexibleSchedule) ...[
                      _buildInfoRow(
                        Icons.date_range,
                        '実施期間',
                        '${_formatDate(widget.experiment.experimentPeriodStart)} ~ ${_formatDate(widget.experiment.experimentPeriodEnd)}',
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '予約制・日時選択可',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      _buildInfoRow(
                        Icons.calendar_today,
                        '実施日時',
                        _getExperimentDateTimeText(),
                        Colors.blue,
                      ),
                    if (widget.experiment.duration != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.timer,
                        '所要時間',
                        '約${widget.experiment.duration}分',
                        Colors.green,
                      ),
                    ],
                    if (widget.experiment.maxParticipants != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.group,
                        '募集人数',
                        '最大${widget.experiment.maxParticipants}名',
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 実験概要
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '実験概要',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.experiment.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            // 詳細内容
            if (widget.experiment.detailedContent != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: Color(0xFF8E1728),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '詳細内容',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8E1728),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.experiment.detailedContent!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 参加条件
            if (widget.experiment.requirements.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '参加条件',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.experiment.requirements.map((requirement) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(requirement),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            // 特別な同意項目
            if (widget.experiment.consentItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '特別な同意項目',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'この実験に参加する際は、以下の項目への同意が必要です：',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.experiment.consentItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _detailConsentChecked[index],
                                        onChanged: (value) {
                                          setState(() {
                                            _detailConsentChecked[index] = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.amber[700],
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _detailConsentChecked[index] = !_detailConsentChecked[index];
                                          });
                                        },
                                        child: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.amber[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 柔軟なスケジュール調整の場合はカレンダー表示（自分の実験でない場合のみ）
            if (widget.experiment.allowFlexibleSchedule && 
                !widget.isMyExperiment &&
                (_auth.currentUser == null || widget.experiment.creatorId != _auth.currentUser!.uid)) ...[
              const SizedBox(height: 16),
              // 募集人数上限チェック
              if (widget.experiment.maxParticipants != null &&
                  widget.experiment.participants.length >= widget.experiment.maxParticipants!)
                Card(
                  color: Colors.grey.shade200,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '募集終了',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '募集人数に達しました（${widget.experiment.participants.length}/${widget.experiment.maxParticipants}名）',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.calendar_month,
                          color: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                            ? Colors.grey
                            : const Color(0xFF8E1728),
                        ),
                        title: Text(
                          '予約日時を選択',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                              ? Colors.grey
                              : null,
                          ),
                        ),
                        subtitle: Text(
                          (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                            ? '同意項目にチェックしてから日時を選択してください'
                            : widget.experiment.maxParticipants != null
                              ? 'カレンダーから希望の日時を選んでください（残り${widget.experiment.maxParticipants! - widget.experiment.participants.length}名）'
                              : 'カレンダーから希望の日時を選んでください',
                          style: TextStyle(
                            color: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                              ? Colors.grey
                              : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            _showCalendar
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                            color: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                              ? Colors.grey
                              : null,
                          ),
                          onPressed: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                            ? null
                            : () {
                                setState(() {
                                  _showCalendar = !_showCalendar;
                                });
                              },
                        ),
                        onTap: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                          ? null
                          : () {
                              setState(() {
                                _showCalendar = !_showCalendar;
                              });
                            },
                        enabled: !(widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked)),
                      ),
                      if (_showCalendar)
                        ExperimentCalendarView(
                          experiment: widget.experiment,
                          onSlotSelected: _handleSlotSelection,
                        ),
                    ],
                  ),
                ),
            ],

            // 予約状態の表示
            if (_currentUserReservation != null && !widget.isMyExperiment) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '予約済み',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      if (_reservedSlot != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '予約日時: ${_formatDateTime(_reservedSlot!.startTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (_currentUserReservation!.canCancel(widget.experiment, slot: _reservedSlot)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleCancelReservation,
                            icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cancel, color: Colors.red),
                            label: const Text(
                              '予約をキャンセル',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
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
              ),
            ],

            const SizedBox(height: 24),

            // 参加ボタンまたはキャンセルボタン（予約がない場合、かつ予約制でない場合のみ表示）
            if (!widget.isMyExperiment && 
                _currentUserReservation == null &&
                !widget.experiment.allowFlexibleSchedule &&
                (_auth.currentUser == null || widget.experiment.creatorId != _auth.currentUser!.uid)) ...[// 自分の実験でない場合のみ
              // 募集人数上限チェック
              if (widget.experiment.maxParticipants != null &&
                  widget.experiment.participants.length >= widget.experiment.maxParticipants!) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '募集人数に達しました（${widget.experiment.participants.length}/${widget.experiment.maxParticipants}名）',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_isParticipating && _canCancelParticipation()) ...[
                // キャンセルボタン（参加予定でキャンセル可能な場合）
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showCancelConfirmDialog,
                    icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cancel),
                    label: const Text('参加をキャンセル'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (_isParticipating && !_canCancelParticipation()) ...[
                // 参加予定表示（キャンセル不可）
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        '参加予定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                // 参加ボタン
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || 
                        (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                      ? null // 読み込み中、または同意項目未チェックの場合は無効化
                      : () => _handleDirectApplication(),
                    icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.experiment.type == ExperimentType.survey
                                ? Icons.assignment
                                : Icons.send,
                        ),
                    label: Text(
                      (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                            ? 'すべての同意項目にチェックしてください'
                            : widget.experiment.type == ExperimentType.survey
                                ? '今すぐ参加'
                                : '参加申請する',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (widget.experiment.consentItems.isNotEmpty && !_detailConsentChecked.every((checked) => checked))
                          ? Colors.grey 
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 実験日時のテキストを取得
  String _getExperimentDateTimeText() {
    // 固定日時の実験の場合
    if (!widget.experiment.allowFlexibleSchedule && widget.experiment.fixedExperimentDate != null) {
      final dateStr = DateFormat('yyyy/MM/dd').format(widget.experiment.fixedExperimentDate!);
      if (widget.experiment.fixedExperimentTime != null) {
        final hour = widget.experiment.fixedExperimentTime!['hour'] ?? 0;
        final minute = widget.experiment.fixedExperimentTime!['minute'] ?? 0;
        return '$dateStr ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      return dateStr;
    }
    
    // それ以外の場合（フォールバック）
    return _formatDateTime(widget.experiment.recruitmentStartDate);
  }

  /// 実験参加がキャンセル可能かどうかを判定（履歴画面と同じ条件）
  bool _canCancelParticipation() {
    // 既に評価済みの場合はキャンセル不可
    final userId = _auth.currentUser?.uid ?? '';
    if (widget.experiment.hasEvaluated(userId)) {
      return false;
    }
    
    // 実験が完了している場合はキャンセル不可
    if (widget.experiment.status == ExperimentStatus.completed) {
      return false;
    }
    
    // アンケート型は常にキャンセル可能
    if (widget.experiment.type == ExperimentType.survey) {
      return true;
    }
    
    // 固定日時の実験の場合
    if (widget.experiment.fixedExperimentDate != null) {
      final now = DateTime.now();
      final experimentDate = widget.experiment.fixedExperimentDate!;
      
      // 実験日の1日前までキャンセル可能
      final cancelDeadline = experimentDate.subtract(const Duration(days: 1));
      return now.isBefore(cancelDeadline);
    }
    
    // 柔軟なスケジュールの場合
    if (widget.experiment.allowFlexibleSchedule) {
      // 予約がある場合は予約のキャンセル可否をチェック
      if (_currentUserReservation != null) {
        return _currentUserReservation!.canCancel(widget.experiment, slot: _reservedSlot);
      }
      return true; // 予約がない場合はキャンセル可能
    }
    
    // その他の場合はキャンセル可能
    return true;
  }

  /// キャンセル確認ダイアログを表示
  Future<void> _showCancelConfirmDialog() async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('予約のキャンセル'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'この実験の予約をキャンセルしますか？',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '重要: キャンセルした場合、あなたのアカウントにBad評価が自動的に記録されます。これは他の実験者からの信頼性に影響する可能性があります。',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'キャンセル理由（任意）',
                hintText: '急用のため、体調不良など...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('キャンセルする（Bad評価が付きます）'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      await _cancelParticipation(reasonController.text);
    }
    
    reasonController.dispose();
  }

  /// 参加をキャンセル
  Future<void> _cancelParticipation(String reason) async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 実験サービスを使って参加キャンセル
        await _experimentService.cancelParticipation(
          widget.experiment.id, 
          user.uid,
          reason: reason.isNotEmpty ? reason : null,
        );
        
        // キャンセルしたユーザーに自動的にBad評価を付与
        await _userService.updateUserRatings(
          userId: user.uid,
          isGood: false, // Bad評価
        );
        
        // キャンセル通知を送信
        final notificationService = NotificationService();
        
        // 実験者への通知
        await notificationService.createExperimentCancelledNotification(
          userId: widget.experiment.creatorId,
          participantName: _experimenterName ?? user.email ?? '参加者',
          experimentTitle: widget.experiment.title,
          experimentId: widget.experiment.id,
          reason: reason.isNotEmpty ? reason : null,
        );
        
        // キャンセルした本人への通知（Bad評価が付いたことを通知）
        await notificationService.createNotification(
          userId: user.uid,
          type: NotificationType.adminMessage,
          title: 'キャンセルによるペナルティ',
          message: '「${widget.experiment.title}」のキャンセルにより、Bad評価が1つ追加されました。今後の実験参加の信頼性に影響する可能性があります。',
          data: {
            'experimentId': widget.experiment.id,
            'penaltyType': 'bad_rating',
          },
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('参加をキャンセルしました'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        
        // 参加状態を更新
        setState(() {
          _isParticipating = false;
        });
        
        // 参加状態を再チェック
        await _checkParticipation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャンセルに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 予約キャンセル処理
  Future<void> _handleCancelReservation() async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約のキャンセル'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'この実験の予約をキャンセルしますか？',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'キャンセル理由（任意）',
                hintText: '急用のため、体調不良など...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await _reservationService.cancelReservation(
          _currentUserReservation!.id, 
          reasonController.text.isNotEmpty ? reasonController.text : null,
        );
        
        // 実験の参加者リストからも削除
        final user = _auth.currentUser;
        if (user != null) {
          await _experimentService.leaveExperiment(widget.experiment.id, user.uid);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('予約をキャンセルしました'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 参加状態を更新
          setState(() {
            _isParticipating = false;
          });
          
          // 予約情報を再読み込み
          await _loadUserReservation();
          await _checkParticipation();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('キャンセルに失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
    
    reasonController.dispose();
  }

  /// 情報行のウィジェット
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// 通常の実験の参加申請ダイアログ（StatefulWidgetとして実装）
class _DirectApplicationDialog extends StatefulWidget {
  final Experiment experiment;

  const _DirectApplicationDialog({
    required this.experiment,
  });

  @override
  State<_DirectApplicationDialog> createState() => _DirectApplicationDialogState();
}

class _DirectApplicationDialogState extends State<_DirectApplicationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('実験への参加確認'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${widget.experiment.title}」に参加申請しますか？'),
            const SizedBox(height: 16),
            // 相互評価必須の注意書きを追加
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '重要なお願い',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '実験終了後は必ず相互評価を行ってください。相互評価により実験の完了が確認されます。',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.experiment.fixedExperimentDate != null) ...[
              const SizedBox(height: 12),
              const Text('実験日時:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('yyyy年MM月dd日').format(widget.experiment.fixedExperimentDate!)),
              if (widget.experiment.fixedExperimentTime != null) ...[
                Text('時刻: ${widget.experiment.fixedExperimentTime!['hour']}:${widget.experiment.fixedExperimentTime!['minute'].toString().padLeft(2, '0')}'),
              ],
            ],
            if (widget.experiment.reward > 0) ...[
              const SizedBox(height: 8),
              const Text('謝礼:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.experiment.reward}円'),
            ],
            // 同意項目の確認（画面上でチェック済みであることを前提）
            if (widget.experiment.consentItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '特別な同意項目への同意が確認されました',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('参加する'),
        ),
      ],
    );
  }
}

/// アンケート参加ダイアログ（StatefulWidgetとして実装）  
class _SurveyParticipationDialog extends StatefulWidget {
  final Experiment experiment;

  const _SurveyParticipationDialog({
    required this.experiment,
  });

  @override
  State<_SurveyParticipationDialog> createState() => _SurveyParticipationDialogState();
}

class _SurveyParticipationDialogState extends State<_SurveyParticipationDialog> {
  late List<bool> consentChecked;

  @override
  void initState() {
    super.initState();
    consentChecked = List.filled(widget.experiment.consentItems.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = widget.experiment.consentItems.isEmpty || 
        consentChecked.every((checked) => checked);
        
    return AlertDialog(
      title: const Text('アンケートへの参加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${widget.experiment.title}」のアンケートに参加しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.experiment.surveyUrl != null 
                        ? '参加後、アンケートURLが表示されます'
                        : '参加後、実験者から個別チャットでアンケートの詳細が送られます',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.experiment.reward > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text('謝礼: ${widget.experiment.reward}円', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            // 特別な同意項目がある場合のチェックボックス
            if (widget.experiment.consentItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '以下の項目にすべて同意してください：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.experiment.consentItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Checkbox(
                        value: consentChecked[index],
                        onChanged: (value) {
                          setState(() {
                            consentChecked[index] = value ?? false;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              consentChecked[index] = !consentChecked[index];
                            });
                          },
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: allChecked ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: allChecked ? Colors.orange : Colors.grey.shade300,
          ),
          child: Text(
            allChecked ? '参加する' : 'すべての項目に同意してください',
            style: TextStyle(
              color: allChecked ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 予約確認ダイアログ（StatefulWidgetとして実装）
class _ReservationConfirmDialog extends StatefulWidget {
  final Experiment experiment;
  final ExperimentSlot slot;

  const _ReservationConfirmDialog({
    required this.experiment,
    required this.slot,
  });

  @override
  State<_ReservationConfirmDialog> createState() => _ReservationConfirmDialogState();
}

class _ReservationConfirmDialogState extends State<_ReservationConfirmDialog> {
  late List<bool> consentChecked;

  @override
  void initState() {
    super.initState();
    // 同意項目のチェック状態を初期化（すべてfalse）
    consentChecked = List.filled(widget.experiment.consentItems.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('予約確認'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '以下の日時で予約しますか？',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy年MM月dd日(E)', 'ja').format(widget.slot.startTime),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('HH:mm').format(widget.slot.startTime)} - ${DateFormat('HH:mm').format(widget.slot.endTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 特別な同意項目がある場合のチェックボックス
            if (widget.experiment.consentItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '以下の項目にすべて同意してください：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.experiment.consentItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Checkbox(
                        value: consentChecked[index],
                        onChanged: (value) {
                          setState(() {
                            consentChecked[index] = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF8E1728),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              consentChecked[index] = !consentChecked[index];
                            });
                          },
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: widget.experiment.consentItems.isEmpty || 
              consentChecked.every((checked) => checked)
            ? () => Navigator.pop(context, true)
            : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E1728),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            widget.experiment.consentItems.isEmpty || 
                consentChecked.every((checked) => checked)
              ? '予約する' 
              : 'すべての項目に同意してください',
            style: TextStyle(
              color: widget.experiment.consentItems.isEmpty || 
                  consentChecked.every((checked) => checked)
                ? Colors.white 
                : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}