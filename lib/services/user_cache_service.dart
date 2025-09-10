import '../models/app_user.dart';
import 'user_service.dart';

/// ユーザー情報のキャッシュを管理するサービス
class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final UserService _userService = UserService();
  final Map<String, AppUser?> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// ユーザー情報を取得（キャッシュ優先）
  Future<AppUser?> getUserById(String userId) async {
    // キャッシュをチェック
    if (_cache.containsKey(userId)) {
      final cachedTime = _cacheTime[userId];
      if (cachedTime != null && 
          DateTime.now().difference(cachedTime) < _cacheExpiry) {
        return _cache[userId];
      }
    }

    // キャッシュがない、または期限切れの場合は取得
    try {
      final user = await _userService.getUserById(userId);
      _cache[userId] = user;
      _cacheTime[userId] = DateTime.now();
      return user;
    } catch (e) {
      return null;
    }
  }

  /// 複数のユーザー情報を一括取得
  Future<Map<String, AppUser?>> getUsersByIds(List<String> userIds) async {
    final Map<String, AppUser?> result = {};
    final List<String> uncachedIds = [];

    // キャッシュから取得
    for (final userId in userIds) {
      if (_cache.containsKey(userId)) {
        final cachedTime = _cacheTime[userId];
        if (cachedTime != null && 
            DateTime.now().difference(cachedTime) < _cacheExpiry) {
          result[userId] = _cache[userId];
        } else {
          uncachedIds.add(userId);
        }
      } else {
        uncachedIds.add(userId);
      }
    }

    // キャッシュにないユーザーを一括取得
    if (uncachedIds.isNotEmpty) {
      final futures = uncachedIds.map((id) => _userService.getUserById(id));
      final users = await Future.wait(futures);
      
      for (int i = 0; i < uncachedIds.length; i++) {
        final userId = uncachedIds[i];
        final user = users[i];
        _cache[userId] = user;
        _cacheTime[userId] = DateTime.now();
        result[userId] = user;
      }
    }

    return result;
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  /// 特定のユーザーのキャッシュをクリア
  void clearUserCache(String userId) {
    _cache.remove(userId);
    _cacheTime.remove(userId);
  }
}