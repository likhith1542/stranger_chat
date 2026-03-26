// lib/services/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message_model.dart';

class StorageService {
  static const _messagesBox = 'messages';

  Future<void> initialize() async {
    await Hive.openBox<MessageModel>(_messagesBox);
  }

  Box<MessageModel> get _box => Hive.box<MessageModel>(_messagesBox);

  Future<void> saveMessage(MessageModel message) async {
    await _box.put(message.id, message);
  }

  List<MessageModel> getMessagesForSession(String sessionId) {
    return _box.values
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> deleteSession(String sessionId) async {
    final keys = _box.toMap().entries
        .where((e) => (e.value).sessionId == sessionId)
        .map((e) => e.key)
        .toList();
    await _box.deleteAll(keys);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final msg = _box.get(messageId);
    if (msg != null) {
      await _box.put(messageId, msg.copyWith(status: status));
    }
  }
}
