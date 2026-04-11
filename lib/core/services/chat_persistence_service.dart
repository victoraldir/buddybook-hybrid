import 'dart:convert';

import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPersistenceService {
  static String _key(String bookId) => 'chat_history_$bookId';

  static Future<List<ChatMessage>> loadHistory(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key(bookId));
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHistory(
    String bookId,
    Iterable<ChatMessage> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((msg) => msg.toJson()).toList();
    await prefs.setString(_key(bookId), jsonEncode(jsonList));
  }

  static Future<void> clearHistory(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(bookId));
  }
}
