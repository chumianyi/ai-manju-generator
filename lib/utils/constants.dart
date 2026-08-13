import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'AI漫剧生成器';
  static const String appVersion = '1.0.0';
  static const String license = 'GPL-3.0';

  static const int maxContextTokens = 2650000;
  static const int defaultContextTokens = 128000;

  static const List<String> videoRatios = ['9:16', '16:9', '1:1', '4:3', '3:4'];
  static const String defaultVideoRatio = '9:16';

  static const List<String> videoStyles = [
    '日漫风格',
    '国漫风格',
    '美漫风格',
    '赛博朋克',
    '水墨古风',
    'Q版可爱',
    '写实风格',
    '像素风格',
    '蒸汽波',
    '暗黑哥特',
  ];

  static const List<String> aiProtocols = [
    'OpenAI 兼容',
    '自定义 HTTP',
    'Anthropic Claude',
    'Google Gemini',
  ];

  static const List<String> modelTypes = ['语言模型', '视频模型', '图片模型'];

  static const Color primaryColor = Color(0xFF4A90D9);
  static const Color secondaryColor = Color(0xFFFF8FAB);
  static const Color accentColor = Color(0xFF6C5CE7);
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgDark = Color(0xFF1A1A2E);
}
