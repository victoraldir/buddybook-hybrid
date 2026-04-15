import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../constants/firebase_constants.dart';

class ChatPersistenceService {
  final FirebaseDatabase _database;

  ChatPersistenceService(this._database);

  String _path(String userId, String bookId) => 
      '${FirebaseConstants.usersPath}/$userId/${FirebaseConstants.booksPath}/$bookId/${FirebaseConstants.chatSessionsField}';

  Future<List<ChatMessage>> loadHistory(String userId, String bookId) async {
    try {
      final snapshot = await _database.ref(_path(userId, bookId)).get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<dynamic> messages = data[FirebaseConstants.chatMessagesField] ?? [];
      
      return messages
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistory(
    String userId,
    String bookId,
    Iterable<ChatMessage> history,
  ) async {
    try {
      final jsonList = history.map((msg) => msg.toJson()).toList();
      await _database.ref(_path(userId, bookId)).update({
        FirebaseConstants.chatMessagesField: jsonList,
        FirebaseConstants.chatTimestampField: ServerValue.timestamp,
      });
    } catch (e) {
      // Log error
    }
  }

  Future<void> clearHistory(String userId, String bookId) async {
    try {
      await _database.ref(_path(userId, bookId)).remove();
    } catch (e) {
      // Log error
    }
  }
}
