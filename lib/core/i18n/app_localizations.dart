import 'package:flutter/widgets.dart';
import 'strings/en_us.dart';
import 'strings/zh_tw.dart';

/// 國際化系統
/// 使用 Map-based 翻譯，支援 en_US 與 zh_TW
/// 
/// 使用方式：
/// ```dart
/// final s = S.of(context);
/// Text(s.t('start_game')) // 根據當前語系顯示對應文字
/// ```
class S {
  final Locale locale;

  S(this.locale);

  /// 從 BuildContext 取得 S 實例
  /// 透過 Localizations 或直接使用 Locale
  static S of(BuildContext context) {
    return S(Localizations.localeOf(context));
  }

  /// 從 Locale 直接建立 S 實例（不需要 context）
  static S fromLocale(Locale locale) {
    return S(locale);
  }

  /// 取得所有支援的語系
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'TW'),
  ];

  /// 取得翻譯字典
  Map<String, String> get _strings {
    switch (locale.languageCode) {
      case 'en':
        return enUS;
      case 'zh':
      default:
        return zhTW;
    }
  }

  /// 翻譯 key → 對應語系文字
  /// 如果 key 不存在，回傳 key 本身（方便除錯）
  String t(String key, [Map<String, String>? params]) {
    String text = _strings[key] ?? key;

    // 支援參數替換：{param} → 實際值
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }

    return text;
  }

  /// 取得當前語系名稱
  String get localeName {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
      default:
        return '繁體中文';
    }
  }
}
