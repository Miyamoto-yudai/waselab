import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/experiment.dart';
import '../models/experiment_slot.dart';
import '../models/experiment_reservation.dart';
import '../services/reservation_service.dart';
import '../services/experiment_service.dart';
import '../widgets/experiment_calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

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
  bool _showCalendar = false;
  bool _isLoading = false;
  bool _isParticipating = false;
  String? _experimenterName;
  ExperimentReservation? _currentUserReservation;
  ExperimentSlot? _reservedSlot;

  @override
  void initState() {
    super.initState();
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
      builder: (context) => AlertDialog(
        title: const Text('予約確認'),
        content: Column(
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
                        DateFormat('yyyy年MM月dd日(E)', 'ja').format(slot.startTime),
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
                        '${DateFormat('HH:mm').format(slot.startTime)} - ${DateFormat('HH:mm').format(slot.endTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('予約する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _makeReservation(slot);
    }
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

  /// 予約を実行
  Future<void> _makeReservation(ExperimentSlot slot) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインが必要です');
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

      // 予約を作成
      await _reservationService.createReservation(
        userId: user.uid,
        experimentId: widget.experiment.id,
        slotId: slot.id,
      );

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('予約が完了しました。実験終了後は必ず相互評価をお願いします'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
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

      // アンケートタイプの場合は特別な処理
      if (widget.experiment.type == ExperimentType.survey) {
        // アンケート参加確認ダイアログ
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('アンケートへの参加'),
            content: Column(
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
                if (widget.experiment.reward != null && widget.experiment.reward! > 0) ...[
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
              ],
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

      // 通常の実験の場合の確認ダイアログ
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('実験への参加確認'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('「${widget.experiment.title}」に参加申請しますか？'),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
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
              if (widget.experiment.experimentDate != null) ...[
                const Text('実験日時:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('yyyy年MM月dd日 HH:mm').format(widget.experiment.experimentDate!)),
                const SizedBox(height: 8),
              ],
              if (widget.experiment.reward != null && widget.experiment.reward! > 0) ...[
                const Text('謝礼:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${widget.experiment.reward}円'),
              ],
            ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('実験への参加申請が完了しました。実験終了後は必ず相互評価をお願いします'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
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
                            '参加者数: ${widget.experiment.participants?.length ?? 0}名',
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
                    if (_experimenterName != null)
                      _buildInfoRow(
                        Icons.person,
                        '実験者',
                        _experimenterName!,
                        const Color(0xFF8E1728),
                      ),
                    if (_experimenterName != null)
                      const SizedBox(height: 8),
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

            // 柔軟なスケジュール調整の場合はカレンダー表示（自分の実験でない場合のみ）
            if (widget.experiment.allowFlexibleSchedule && 
                !widget.isMyExperiment &&
                (_auth.currentUser == null || widget.experiment.creatorId != _auth.currentUser!.uid)) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF8E1728),
                      ),
                      title: const Text(
                        '予約日時を選択',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('カレンダーから希望の日時を選んでください'),
                      trailing: IconButton(
                        icon: Icon(
                          _showCalendar
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCalendar = !_showCalendar;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                        });
                      },
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

            // 応募ボタン（予約がない場合、かつ予約制でない場合のみ表示）
            if (!widget.isMyExperiment && 
                _currentUserReservation == null &&
                !widget.experiment.allowFlexibleSchedule &&
                (_auth.currentUser == null || widget.experiment.creatorId != _auth.currentUser!.uid)) // 自分の実験でない場合のみ
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isParticipating || _isLoading
                    ? null // 既に参加している、読み込み中の場合は無効化
                    : () => _handleDirectApplication(),
                  icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isParticipating
                          ? Icons.check_circle
                          : widget.experiment.type == ExperimentType.survey
                              ? Icons.assignment
                              : Icons.send,
                      ),
                  label: Text(
                    _isParticipating
                      ? '参加予定'
                      : widget.experiment.type == ExperimentType.survey
                          ? '今すぐ参加'
                          : '参加申請する',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isParticipating ? Colors.grey : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
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