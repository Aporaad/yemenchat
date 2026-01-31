// =============================================================================
// YemenChat - Security Log Model
// =============================================================================
// This model represents a security/activity log entry.
// Used for tracking user actions like login, logout, password changes.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for security action types
enum SecurityAction {
  login,
  logout,
  passwordChange,
  profileUpdate,
  accountDelete,
}

/// Security log model class for activity tracking
class SecurityLogModel {
  // Unique log ID
  final String id;

  // ID of the user this log belongs to
  final String userId;

  // Type of action performed
  final SecurityAction action;

  // Timestamp of the action
  final DateTime timestamp;

  // Device/browser information
  final String? deviceInfo;

  // IP address (if available)
  final String? ipAddress;

  /// Constructor
  SecurityLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.deviceInfo,
    this.ipAddress,
  });

  /// Create SecurityLogModel from Firestore document
  factory SecurityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecurityLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: _parseAction(data['action']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
    );
  }

  /// Parse action string to enum
  static SecurityAction _parseAction(String? actionStr) {
    switch (actionStr) {
      case 'login':
        return SecurityAction.login;
      case 'logout':
        return SecurityAction.logout;
      case 'password_change':
        return SecurityAction.passwordChange;
      case 'profile_update':
        return SecurityAction.profileUpdate;
      case 'account_delete':
        return SecurityAction.accountDelete;
      default:
        return SecurityAction.login;
    }
  }

  /// Convert action enum to string
  static String _actionToString(SecurityAction action) {
    switch (action) {
      case SecurityAction.login:
        return 'login';
      case SecurityAction.logout:
        return 'logout';
      case SecurityAction.passwordChange:
        return 'password_change';
      case SecurityAction.profileUpdate:
        return 'profile_update';
      case SecurityAction.accountDelete:
        return 'account_delete';
    }
  }

  /// Get human-readable action description
  String get actionDescription {
    switch (action) {
      case SecurityAction.login:
        return 'Logged in';
      case SecurityAction.logout:
        return 'Logged out';
      case SecurityAction.passwordChange:
        return 'Changed password';
      case SecurityAction.profileUpdate:
        return 'Updated profile';
      case SecurityAction.accountDelete:
        return 'Deleted account';
    }
  }

  /// Convert SecurityLogModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': _actionToString(action),
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }

  @override
  String toString() {
    return 'SecurityLogModel(id: $id, userId: $userId, action: $action)';
  }
}
