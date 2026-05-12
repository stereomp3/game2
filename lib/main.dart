import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/data/data_manager.dart';

/// 遊戲入口點
/// 使用 ProviderScope 包裹整個 App，確保 Riverpod 狀態管理可用
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataManager.init();
  runApp(
    const ProviderScope(
      child: GameApp(),
    ),
  );
}
