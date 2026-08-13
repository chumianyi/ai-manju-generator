import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_config.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _configKey = 'app_config';
  static const String _chatKey = 'chat_history';

  static Future<AppConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_configKey);
    if (jsonStr == null) return AppConfig();
    try {
      return AppConfig.fromJson(jsonStr);
    } catch (_) {
      return AppConfig();
    }
  }

  static Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, config.toJson());
  }

  static Future<List<ChatMessage>> loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_chatKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChat(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final list = messages.map((m) => m.toMap()).toList();
    await prefs.setString(_chatKey, jsonEncode(list));
  }

  static Future<void> clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
  }

  static Future<String> getVideoDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${dir.path}/videos');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir.path;
  }

  static Future<String> getTempDir() async {
    final dir = await getTemporaryDirectory();
    final tempDir = Directory('${dir.path}/manju_temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir.path;
  }
}
