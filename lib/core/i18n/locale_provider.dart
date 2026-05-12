import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 當前語系 Provider（Riverpod 3.x 使用 NotifierProvider）
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

/// 語系狀態管理器
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // 預設繁體中文
    return const Locale('zh', 'TW');
  }

  /// 切換語系
  void setLocale(Locale locale) {
    state = locale;
  }

  /// 切換至英文
  void toEnglish() => setLocale(const Locale('en', 'US'));

  /// 切換至繁體中文
  void toChinese() => setLocale(const Locale('zh', 'TW'));

  /// 切換語系（toggle）
  void toggle() {
    if (state.languageCode == 'zh') {
      toEnglish();
    } else {
      toChinese();
    }
  }
}
