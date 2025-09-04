import 'package:cloud_firestore/cloud_firestore.dart';

/// 管理者モデル
class Admin {
  final String uid;
  final String email;
  final String name;
  final String role; // 'super_admin', 'admin', 'moderator'など
  final List<String> permissions; // 権限リスト
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  Admin({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Admin(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  // 権限チェック
  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'super_admin';
  }

  // 利用可能な権限
  static const List<String> availablePermissions = [
    'view_users',
    'edit_users',
    'view_chats',
    'send_support_messages',
    'send_announcements',
    'view_experiments',
    'edit_experiments',
    'view_statistics',
    'manage_admins',
  ];
}