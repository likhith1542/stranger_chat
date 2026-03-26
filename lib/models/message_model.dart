// lib/models/message_model.dart
import 'package:hive_flutter/hive_flutter.dart';

part 'message_model.g.dart';

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId; // chat session between two users

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final int timestamp;

  @HiveField(5)
  MessageStatus status;

  @HiveField(6)
  final MessageType type;

  MessageModel({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.content,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  bool isMe(String localUserId) => senderId == localUserId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'senderId': senderId,
        'content': content,
        'timestamp': timestamp,
        'type': type.index,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        senderId: json['senderId'] as String,
        content: json['content'] as String,
        timestamp: json['timestamp'] as int,
        type: MessageType.values[(json['type'] as int? ?? 0)],
        status: MessageStatus.delivered,
      );

  MessageModel copyWith({MessageStatus? status}) {
    return MessageModel(
      id: id,
      sessionId: sessionId,
      senderId: senderId,
      content: content,
      timestamp: timestamp,
      type: type,
      status: status ?? this.status,
    );
  }
}

@HiveType(typeId: 3)
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  @HiveField(2)
  delivered,

  @HiveField(3)
  failed,
}

@HiveType(typeId: 4)
enum MessageType {
  @HiveField(0)
  text,

  @HiveField(1)
  system,
}
