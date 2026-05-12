import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/constants/color_palette.dart';

/// 遊戲主 App Widget
class GameApp extends ConsumerWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      title: 'Survival Roguelite',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameColors.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: GameColors.accentGold,
          secondary: GameColors.accentCyan,
          surface: GameColors.surfaceDark,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
        ),
      ),
      initialRoute: AppRouter.startScreen,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
