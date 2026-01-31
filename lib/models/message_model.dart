// =============================================================================
// YemenChat - Message Model
// =============================================================================
// This model represents a single message in a chat conversation.
// Messages are stored as subcollections under each chat document.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for message delivery status
enum MessageStatus {
  sending, // Message is being sent
  sent, // Message sent to server
  delivered, // Message delivered to recipient's device
  seen, // Message has been read by recipient
}

/// Message model class representing a single chat message
class MessageModel {
  // Unique message ID
  final String id;

  // ID of the chat this message belongs to
  final String chatId;

  // ID of the user who sent this message
  final String senderId;

  // Text content of the message (can be empty if image-only)
  final String text;

  // URL of attached image (nullable)
  final String? imageUrl;

  // Timestamp when message was sent
  final DateTime time;

  // Current delivery status of the message
  final MessageStatus status;

  /// Constructor
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.time,
    this.status = MessageStatus.sending,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc, String chatId) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: chatId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      time: (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(data['status']),
    );
  }

  /// Parse status string to enum
  static MessageStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'seen':
        return MessageStatus.seen;
      default:
        return MessageStatus.sending;
    }
  }

  /// Convert status enum to string
  static String _statusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.seen:
        return 'seen';
    }
  }

  /// Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'time': Timestamp.fromDate(time),
      'status': _statusToString(status),
    };
  }

  /// Check if this message has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if this message has text
  bool get hasText => text.isNotEmpty;

  /// Get status as string for Firestore
  String get statusString {
    return status.toString().split('.').last;
  }

  /// Check if message is an image message
  bool get isImageMessage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Check if message is image-only (no text)
  bool get isImageOnly => isImageMessage && !hasText;

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? time,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, text: $text)';
  }
}
